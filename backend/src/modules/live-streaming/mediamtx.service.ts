// backend/src/modules/live-streaming/mediamtx.service.ts
//
// Service for managing MediaMTX broadcast paths dynamically.
//
// When a WHIP session is created, the backend registers the path on MediaMTX
// with the exact Cloudinary RTMP ingest URL (including the stream key).
// MediaMTX's runOnAvailable hook launches FFmpeg to re-stream to Cloudinary
// the moment the browser's WHIP publisher connects.

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Represents a MediaMTX path configuration payload for the REST API. */
interface MtxPathConfig {
  /** Full Cloudinary RTMP destination: rtmp://live.cloudinary.com/streams/<key> */
  rtmpDestination: string;
  /** Whether to auto-restart the FFmpeg relay if it crashes */
  restartOnFail?: boolean;
}

@Injectable()
export class MediaMtxService {
  private readonly logger = new Logger(MediaMtxService.name);

  /** MediaMTX REST API base URL (e.g. http://localhost:9997) */
  private readonly apiBase: string;

  constructor(private readonly configService: ConfigService) {
    // MEDIAMTX_API_URL defaults to localhost for co-located deployments
    this.apiBase =
      configService.get<string>('MEDIAMTX_API_URL')?.replace(/\/$/, '') ??
      'http://localhost:9997';
  }

  /**
   * Register a broadcast path on MediaMTX with a custom runOnAvailable command.
   *
   * The path name must exactly match the segment the browser POSTs WHIP to.
   * Example: if whipUrl = https://mtx.example.com/abc123/whip, path = "abc123".
   *
   * The FFmpeg command reads the WHIP session from RTSP (MediaMTX exposes it)
   * and re-publishes to Cloudinary RTMP using the exact stream key.
   */
  async registerBroadcastPath(
    pathName: string,
    cfg: MtxPathConfig,
  ): Promise<void> {
    const restart = cfg.restartOnFail ?? true;
    // FFmpeg command — reads RTSP (WebRTC→RTSP bridge done by MediaMTX)
    // and pushes H.264 + AAC to Cloudinary RTMP.
    const ffmpegCmd = [
      'ffmpeg',
      '-re',
      '-i',
      `rtsp://127.0.0.1:8554/${pathName}`,
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-ar',
      '44100',
      '-b:a',
      '128k',
      '-f',
      'flv',
      cfg.rtmpDestination,
    ].join(' ');

    const body = {
      runOnAvailable: ffmpegCmd,
      runOnAvailableRestart: restart,
      runOnUnavailable: '',
    };

    const url = `${this.apiBase}/v3/config/paths/add/${encodeURIComponent(pathName)}`;
    this.logger.log(
      `[MediaMTX] Registering path "${pathName}" → ${cfg.rtmpDestination.replace(/\/[^/]+$/, '/<key>')}`,
    );

    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!res.ok) {
        // 409 = path already exists — try PATCH to update it
        if (res.status === 409) {
          await this.patchBroadcastPath(pathName, body);
          return;
        }
        const errBody = await res.text();
        throw new Error(
          `MediaMTX API ${res.status}: ${errBody}`,
        );
      }
      this.logger.log(`[MediaMTX] Path "${pathName}" registered successfully.`);
    } catch (err: any) {
      // Do NOT throw — a missing MediaMTX is degraded but not fatal at session
      // creation time. The error is logged and the WHIP URL is still returned.
      this.logger.error(
        `[MediaMTX] Failed to register path "${pathName}": ${err.message}. ` +
          'Ensure MEDIAMTX_API_URL is set and MediaMTX is reachable.',
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
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      const errBody = await res.text();
      this.logger.warn(
        `[MediaMTX] PATCH for path "${pathName}" failed (${res.status}): ${errBody}`,
      );
    } else {
      this.logger.log(`[MediaMTX] Path "${pathName}" updated via PATCH.`);
    }
  }

  /**
   * Remove a MediaMTX path after the broadcast ends.
   * Failures are swallowed — stale paths are cleaned up on MediaMTX restart.
   */
  async removeBroadcastPath(pathName: string): Promise<void> {
    const url = `${this.apiBase}/v3/config/paths/delete/${encodeURIComponent(pathName)}`;
    try {
      const res = await fetch(url, { method: 'DELETE' });
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
        signal: AbortSignal.timeout(3000),
      });
      return res.ok;
    } catch {
      return false;
    }
  }
}
