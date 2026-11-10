// backend/src/modules/live-streaming/mediamtx.service.ts
//
// Service for managing MediaMTX broadcast paths dynamically.
//
// When a WHIP session is created, the backend registers the path on MediaMTX
// with the exact Cloudinary RTMP ingest URL (including the stream key).
// MediaMTX's runOnAvailable hook launches FFmpeg to re-stream to Cloudinary
// the moment the browser's WHIP publisher connects.

import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Represents a MediaMTX path configuration payload for the REST API. */
interface MtxPathConfig {
  /** Full Cloudinary RTMP destination: rtmp://live.cloudinary.com/streams/<key> */
  rtmpDestination: string;
  /** Whether to auto-restart the FFmpeg relay if it crashes */
  restartOnFail?: boolean;
}

export interface MediaMtxPathStatus {
  exists: boolean;
  ready: boolean;
  bytesReceived: number;
  sourceType: string | null;
  tracks: string[];
  readersCount: number;
}

@Injectable()
export class MediaMtxService {
  private readonly logger = new Logger(MediaMtxService.name);

  /** MediaMTX REST API base URL (e.g. http://localhost:9997) */
  private readonly apiBase: string;
  private readonly apiAuthHeader: string | null;
  private readonly videoCodec: string;

  constructor(private readonly configService: ConfigService) {
    // MEDIAMTX_API_URL defaults to localhost for co-located deployments
    this.apiBase =
      configService.get<string>('MEDIAMTX_API_URL')?.replace(/\/$/, '') ??
      'http://localhost:9997';
    this.videoCodec =
      configService.get<string>('MEDIAMTX_VIDEO_CODEC')?.trim() || 'libx264';

    const apiUser = configService.get<string>('MEDIAMTX_API_USER');
    const apiPass = configService.get<string>('MEDIAMTX_API_PASSWORD');
    this.apiAuthHeader =
      apiUser && apiPass
        ? `Basic ${Buffer.from(`${apiUser}:${apiPass}`).toString('base64')}`
        : null;

    if (/\.onrender\.com:\d+/i.test(this.apiBase)) {
      this.logger.warn(
        `[MediaMTX] MEDIAMTX_API_URL="${this.apiBase}" specifies an explicit port on *.onrender.com. ` +
          'Render Web Services do not expose custom ports like :9997 externally and cannot pass WebRTC UDP media; ' +
          'deploy MediaMTX on a UDP-capable VPS behind TLS and point MEDIAMTX_API_URL there.',
      );
    }
  }

  private buildHeaders(extra?: Record<string, string>): Record<string, string> {
    return {
      ...(this.apiAuthHeader ? { Authorization: this.apiAuthHeader } : {}),
      ...extra,
    };
  }

  /**
   * Build the FFmpeg relay command executed by MediaMTX runOnAvailable.
   * Pulls RTSP over TCP from localhost and pushes FLV (H.264 + AAC) to Cloudinary RTMP.
   */
  buildFfmpegRelayCommand(pathName: string, rtmpDestination: string): string {
    if (!/^[a-zA-Z0-9_-]+$/.test(pathName)) {
      throw new Error(`Invalid MediaMTX path name: "${pathName}"`);
    }
    if (/[\s"';&|`$]/.test(rtmpDestination)) {
      throw new Error('Invalid characters in RTMP destination');
    }

    // Default to libx264 (veryfast/zerolatency, 2s keyframe interval) because WebRTC WHIP
    // browsers may negotiate VP8/VP9/AV1, which FLV/Cloudinary RTMP rejects under -c:v copy.
    const videoArgs =
      this.videoCodec === 'copy'
        ? ['-c:v', 'copy']
        : [
            '-c:v',
            'libx264',
            '-preset',
            'veryfast',
            '-tune',
            'zerolatency',
            '-pix_fmt',
            'yuv420p',
            '-g',
            '60',
            '-keyint_min',
            '60',
            '-sc_threshold',
            '0',
          ];

    return [
      'ffmpeg',
      '-rtsp_transport',
      'tcp',
      '-i',
      `"rtsp://127.0.0.1:8554/${pathName}"`,
      ...videoArgs,
      '-c:a',
      'aac',
      '-ar',
      '44100',
      '-ac',
      '2',
      '-b:a',
      '128k',
      '-flvflags',
      'no_duration_filesize',
      '-f',
      'flv',
      `"${rtmpDestination}"`,
    ].join(' ');
  }

  /**
   * Register a broadcast path on MediaMTX with a custom runOnAvailable command.
   *
   * The path name must exactly match the segment the browser POSTs WHIP to.
   * Example: if whipUrl = https://mtx.example.com/abc123/whip, path = "abc123".
   *
   * Throws ServiceUnavailableException if the MediaMTX control API cannot be reached
   * or rejects path registration so the client never connects to an unregistered path.
   */
  async registerBroadcastPath(
    pathName: string,
    cfg: MtxPathConfig,
  ): Promise<void> {
    const restart = cfg.restartOnFail ?? true;
    const ffmpegCmd = this.buildFfmpegRelayCommand(pathName, cfg.rtmpDestination);

    const body = {
      runOnAvailable: ffmpegCmd,
      runOnAvailableRestart: restart,
      runOnUnavailable: '',
    };

    const url = `${this.apiBase}/v3/config/paths/add/${encodeURIComponent(pathName)}`;
    const maskedDest = cfg.rtmpDestination.replace(/\/[^/]+$/, '/<key>');
    this.logger.log(`[MediaMTX] Registering path "${pathName}" → ${maskedDest}`);

    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: this.buildHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(8000),
      });

      if (!res.ok) {
        // 409 = path already exists — try PATCH to update it
        if (res.status === 409) {
          await this.patchBroadcastPath(pathName, body);
          return;
        }
        const errBody = await res.text().catch(() => '');
        throw new Error(`MediaMTX API ${res.status}: ${errBody.slice(0, 300)}`);
      }
      this.logger.log(`[MediaMTX] Path "${pathName}" registered successfully.`);
    } catch (err: any) {
      this.logger.error(
        `[MediaMTX] Failed to register path "${pathName}" via ${this.apiBase}: ${err.message}. ` +
          'Ensure MEDIAMTX_API_URL is reachable and MediaMTX Control API (:9997) is running.',
      );
      throw new ServiceUnavailableException(
        `WHIP gateway control API is unreachable (${err.message}). ` +
          'Use mobile RTMP ingest or verify MediaMTX deployment and MEDIAMTX_API_URL.',
      );
    }
  }

  /**
   * Update an existing MediaMTX path configuration (used when path already exists).
   */
  private async patchBroadcastPath(
    pathName: string,
    body: Record<string, any>,
  ): Promise<void> {
    const url = `${this.apiBase}/v3/config/paths/patch/${encodeURIComponent(pathName)}`;
    const res = await fetch(url, {
      method: 'PATCH',
      headers: this.buildHeaders({ 'Content-Type': 'application/json' }),
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) {
      const errBody = await res.text().catch(() => '');
      throw new Error(
        `MediaMTX PATCH for path "${pathName}" failed (${res.status}): ${errBody.slice(0, 300)}`,
      );
    }
    this.logger.log(`[MediaMTX] Path "${pathName}" updated via PATCH.`);
  }

  /**
   * Query live ingest metrics for a path from the MediaMTX Control API.
   * Returns null if MediaMTX API is unreachable.
   */
  async getPathStatus(pathName: string): Promise<MediaMtxPathStatus | null> {
    const url = `${this.apiBase}/v3/paths/get/${encodeURIComponent(pathName)}`;
    try {
      const res = await fetch(url, {
        headers: this.buildHeaders(),
        signal: AbortSignal.timeout(4000),
      });
      if (res.status === 404) {
        return {
          exists: false,
          ready: false,
          bytesReceived: 0,
          sourceType: null,
          tracks: [],
          readersCount: 0,
        };
      }
      if (!res.ok) {
        return null;
      }
      const data: any = await res.json();
      return {
        exists: true,
        ready: Boolean(data?.ready),
        bytesReceived: Number(data?.bytesReceived ?? 0),
        sourceType: data?.source?.type ?? null,
        tracks: Array.isArray(data?.tracks) ? data.tracks.map(String) : [],
        readersCount: Array.isArray(data?.readers) ? data.readers.length : 0,
      };
    } catch {
      return null;
    }
  }

  /**
   * Remove a MediaMTX path after the broadcast ends.
   * Failures are swallowed — stale paths are cleaned up on MediaMTX restart.
   */
  async removeBroadcastPath(pathName: string): Promise<void> {
    const url = `${this.apiBase}/v3/config/paths/delete/${encodeURIComponent(pathName)}`;
    try {
      const res = await fetch(url, {
        method: 'DELETE',
        headers: this.buildHeaders(),
        signal: AbortSignal.timeout(4000),
      });
      if (res.ok) {
        this.logger.log(`[MediaMTX] Path "${pathName}" removed.`);
      } else {
        this.logger.warn(
          `[MediaMTX] DELETE path "${pathName}" returned ${res.status}.`,
        );
      }
    } catch (err: any) {
      this.logger.warn(
        `[MediaMTX] Failed to remove path "${pathName}": ${err.message}`,
      );
    }
  }

  /**
   * Health check — returns true if the MediaMTX API is reachable.
   */
  async isHealthy(): Promise<boolean> {
    try {
      const res = await fetch(`${this.apiBase}/v3/config/global/get`, {
        headers: this.buildHeaders(),
        signal: AbortSignal.timeout(3000),
      });
      return res.ok;
    } catch {
      return false;
    }
  }
}
