import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LiveStreamStatus } from '@prisma/client';
import { createHmac, randomBytes, timingSafeEqual } from 'crypto';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { PrismaService } from '../../prisma/prisma.service.js';

export interface DvrVariantDescriptor {
  id: number;
  label: string;
  bandwidth: number;
  width?: number;
  height?: number;
  codecs?: string;
  upstreamUrl: string;
}

export interface DvrSegmentEntry {
  seq: number;
  localFilename: string;
  diskPath: string;
  upstreamUri: string;
  durationSec: number;
  startOffsetSec: number;
  endOffsetSec: number;
  programDateTimeIso?: string;
  discontinuity: boolean;
  byteLength: number;
  contentType: string;
  mapLocalFilename?: string;
}

interface VariantBufferState {
  id: number;
  label: string;
  bandwidth: number;
  width?: number;
  height?: number;
  codecs?: string;
  upstreamUrl: string;
  targetDurationSec: number;
  mediaSequence: number;
  nextLocalSeq: number;
  mapUpstreamUri?: string;
  mapLocalFilename?: string;
  mapDiskPath?: string;
  cumulativeDurationSec: number;
  segments: DvrSegmentEntry[];
  seenUris: Set<string>;
}

interface DvrStreamSession {
  streamId: string;
  upstreamUrl: string;
  startedAtMs: number;
  ended: boolean;
  isPolling: boolean;
  lastError?: string;
  lastUpdatedAtMs: number;
  pollTimer?: NodeJS.Timeout;
  cleanupTimer?: NodeJS.Timeout;
  variants: VariantBufferState[];
}

export interface ParsedMasterVariant {
  bandwidth: number;
  width?: number;
  height?: number;
  codecs?: string;
  uri: string;
}

export interface ParsedMediaSegment {
  uri: string;
  durationSec: number;
  discontinuity: boolean;
  programDateTimeIso?: string;
  mapUri?: string;
}

export interface ParsedMediaPlaylist {
  targetDurationSec: number;
  mediaSequence: number;
  isVodOrEnded: boolean;
  segments: ParsedMediaSegment[];
}

@Injectable()
export class LiveDvrService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(LiveDvrService.name);
  private readonly sessions = new Map<string, DvrStreamSession>();
  private readonly baseDir: string;
  private readonly dvrEnabled: boolean;
  private readonly windowSeconds: number;
  private readonly maxDiskBytes: number;
  private readonly maxVariants: number;
  private readonly pollIntervalMs: number;
  private readonly cleanupDelayMs: number;
  private readonly tokenSecret: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    this.dvrEnabled =
      (this.configService.get<string>('DVR_ENABLED') ?? 'true').toLowerCase() !==
      'false';
    this.windowSeconds = Math.max(
      60,
      Number(this.configService.get<string>('DVR_WINDOW_SECONDS') ?? 1800) ||
        1800,
    );
    const maxMb = Math.max(
      64,
      Number(this.configService.get<string>('DVR_MAX_DISK_MB') ?? 512) || 512,
    );
    this.maxDiskBytes = maxMb * 1024 * 1024;
    this.maxVariants = Math.max(
      1,
      Number(this.configService.get<string>('DVR_MAX_VARIANTS') ?? 2) || 2,
    );
    this.pollIntervalMs = Math.max(
      1000,
      Number(this.configService.get<string>('DVR_POLL_INTERVAL_MS') ?? 1500) ||
        1500,
    );
    this.cleanupDelayMs = Math.max(
      10000,
      Number(this.configService.get<string>('DVR_CLEANUP_DELAY_MS') ?? 120000) ||
        120000,
    );

    this.baseDir = path.join(os.tmpdir(), 'zikrekidusan-dvr');
    this.tokenSecret =
      this.configService.get<string>('JWT_ACCESS_SECRET') ||
      randomBytes(32).toString('hex');
  }

  async onModuleInit(): Promise<void> {
    if (!this.dvrEnabled) return;
    try {
      await fs.promises.rm(this.baseDir, { recursive: true, force: true });
      await fs.promises.mkdir(this.baseDir, { recursive: true });
    } catch (err: any) {
      this.logger.warn(`[DVR] Temp dir init warning: ${err?.message}`);
    }

    // Resume DVR capture for any currently LIVE streams after server restart.
    try {
      const activeStreams = await this.prisma.liveStream.findMany({
        where: {
          status: LiveStreamStatus.LIVE,
          isDvrEnabled: true,
          deletedAt: null,
          hlsUrl: { not: null },
        },
        select: { id: true, hlsUrl: true, startedAt: true },
      });
      for (const s of activeStreams) {
        if (s.hlsUrl) {
          await this.ensureRecording(
            s.id,
            s.hlsUrl,
            s.startedAt ?? new Date(),
            true,
          );
        }
      }
    } catch (err: any) {
      this.logger.warn(
        `[DVR] Could not inspect active LIVE streams on startup: ${err?.message}`,
      );
    }
  }

  async onModuleDestroy(): Promise<void> {
    for (const session of this.sessions.values()) {
      if (session.pollTimer) clearInterval(session.pollTimer);
      if (session.cleanupTimer) clearTimeout(session.cleanupTimer);
    }
    this.sessions.clear();
  }

  get configuredWindowSeconds(): number {
    return this.windowSeconds;
  }

  get enabled(): boolean {
    return this.dvrEnabled;
  }

  createPlaybackToken(streamId: string, ttlSeconds = 21600): string {
    const exp = Math.floor(Date.now() / 1000) + ttlSeconds;
    const payload = `${streamId}:${exp}`;
    const sig = createHmac('sha256', this.tokenSecret)
      .update(payload)
      .digest('hex');
    return `${exp}.${sig}`;
  }

  verifyPlaybackToken(streamId: string, token?: string): boolean {
    if (!token) return false;
    const parts = token.split('.');
    if (parts.length !== 2) return false;
    const exp = Number(parts[0]);
    if (!Number.isFinite(exp) || Math.floor(Date.now() / 1000) > exp) {
      return false;
    }
    const expectedSig = createHmac('sha256', this.tokenSecret)
      .update(`${streamId}:${exp}`)
      .digest('hex');
    const a = Buffer.from(parts[1], 'utf8');
    const b = Buffer.from(expectedSig, 'utf8');
    return a.length === b.length && timingSafeEqual(a, b);
  }

  async ensureRecording(
    streamId: string,
    upstreamHlsUrl: string,
    startedAt: Date = new Date(),
    isDvrEnabled = true,
  ): Promise<void> {
    if (!this.dvrEnabled || !isDvrEnabled || !upstreamHlsUrl) return;
    this.assertSafeId(streamId);

    const existing = this.sessions.get(streamId);
    if (existing) {
      if (existing.cleanupTimer) {
        clearTimeout(sessionCleanup(existing));
        existing.cleanupTimer = undefined;
      }
      if (existing.upstreamUrl === upstreamHlsUrl && !existing.ended) {
        return;
      }
      await this.stopAndPurge(streamId);
    }

    const streamDir = path.join(this.baseDir, streamId);
    await fs.promises.mkdir(streamDir, { recursive: true });

    const session: DvrStreamSession = {
      streamId,
      upstreamUrl: upstreamHlsUrl,
      startedAtMs: startedAt.getTime(),
      ended: false,
      isPolling: false,
      lastUpdatedAtMs: Date.now(),
      variants: [],
    };
    this.sessions.set(streamId, session);

    this.logger.log(
      `[DVR] Started live segment buffer for stream=${streamId} (window=${this.windowSeconds}s)`,
    );

    await this.pollSession(session);
    session.pollTimer = setInterval(() => {
      void this.pollSession(session);
    }, this.pollIntervalMs);
    session.pollTimer.unref?.();
  }

  markStreamEnded(streamId: string): void {
    const session = this.sessions.get(streamId);
    if (!session) return;
    session.ended = true;
    if (session.pollTimer) {
      clearInterval(session.pollTimer);
      session.pollTimer = undefined;
    }
    if (!session.cleanupTimer) {
      session.cleanupTimer = setTimeout(() => {
        void this.stopAndPurge(streamId);
      }, this.cleanupDelayMs);
      session.cleanupTimer.unref?.();
    }
    this.logger.log(
      `[DVR] Marked stream=${streamId} ended; scheduling cleanup in ${Math.round(this.cleanupDelayMs / 1000)}s`,
    );
  }

  async stopAndPurge(streamId: string): Promise<void> {
    const session = this.sessions.get(streamId);
    if (session) {
      if (session.pollTimer) clearInterval(session.pollTimer);
      if (session.cleanupTimer) clearTimeout(session.cleanupTimer);
      this.sessions.delete(streamId);
    }
    try {
      this.assertSafeId(streamId);
      await fs.promises.rm(path.join(this.baseDir, streamId), {
        recursive: true,
        force: true,
      });
    } catch {
      // Ignore cleanup race
    }
  }

  getTimelineMetadata(
    streamId: string,
    options?: { playbackToken?: string },
  ) {
    const session = this.sessions.get(streamId);
    const tokenSuffix = options?.playbackToken
      ? `?dvrToken=${encodeURIComponent(options.playbackToken)}`
      : '';

    const primary = this.pickPrimaryVariant(session);
    const hasSegments = Boolean(primary && primary.segments.length > 0);
    const segments = primary?.segments ?? [];
    const dvrStartOffsetSec = hasSegments ? segments[0].startOffsetSec : 0;
    const liveEdgeOffsetSec = hasSegments
      ? segments[segments.length - 1].endOffsetSec
      : 0;
    const retainedDurationSec = Math.max(
      0,
      liveEdgeOffsetSec - dvrStartOffsetSec,
    );

    return {
      streamId,
      dvrEnabled: this.dvrEnabled,
      active: Boolean(session && !session.ended),
      ended: Boolean(session?.ended),
      hasSegments,
      dvrWindowSeconds: this.windowSeconds,
      retentionMinutes: Math.round(this.windowSeconds / 60),
      targetDurationSec: primary?.targetDurationSec ?? 4,
      dvrStartOffsetSec,
      liveEdgeOffsetSec,
      retainedDurationSec,
      segmentCount: segments.length,
      serverNowIso: new Date().toISOString(),
      streamStartedAtIso: session
        ? new Date(session.startedAtMs).toISOString()
        : null,
      masterPlaylistPath: `/api/streams/${streamId}/dvr/master.m3u8${tokenSuffix}`,
      variants: (session?.variants ?? []).map((v) => ({
        id: v.id,
        label: v.label,
        bandwidth: v.bandwidth,
        width: v.width ?? null,
        height: v.height ?? null,
        codecs: v.codecs ?? null,
        segmentCount: v.segments.length,
        playlistPath: `/api/streams/${streamId}/dvr/variant/${v.id}/playlist.m3u8${tokenSuffix}`,
      })),
    };
  }

  buildMasterPlaylist(streamId: string, playbackToken?: string): string | null {
    const session = this.sessions.get(streamId);
    if (!session) return null;

    const readyVariants = session.variants.filter((v) => v.segments.length > 0);
    if (readyVariants.length === 0) return null;

    const query = playbackToken
      ? `?dvrToken=${encodeURIComponent(playbackToken)}`
      : '';

    const lines = ['#EXTM3U', '#EXT-X-VERSION:7'];
    for (const v of readyVariants) {
      const attrs = [`BANDWIDTH=${Math.max(100000, v.bandwidth)}`];
      if (v.width && v.height) {
        attrs.push(`RESOLUTION=${v.width}x${v.height}`);
      }
      if (v.codecs) {
        attrs.push(`CODECS="${v.codecs}"`);
      }
      attrs.push(`NAME="${v.label}"`);
      lines.push(`#EXT-X-STREAM-INF:${attrs.join(',')}`);
      lines.push(`variant/${v.id}/playlist.m3u8${query}`);
    }
    return `${lines.join('\n')}\n`;
  }

  buildVariantPlaylist(
    streamId: string,
    variantId: number,
    playbackToken?: string,
  ): string | null {
    const session = this.sessions.get(streamId);
    if (!session) return null;

    const variant =
      session.variants.find((v) => v.id === variantId) ??
      this.pickPrimaryVariant(session);
    if (!variant || variant.segments.length === 0) return null;

    const query = playbackToken
      ? `?dvrToken=${encodeURIComponent(playbackToken)}`
      : '';

    const hasMap = Boolean(variant.mapLocalFilename);
    const lines = [
      '#EXTM3U',
      `#EXT-X-VERSION:${hasMap ? 7 : 3}`,
      `#EXT-X-TARGETDURATION:${Math.max(1, Math.ceil(variant.targetDurationSec))}`,
      `#EXT-X-MEDIA-SEQUENCE:${variant.mediaSequence}`,
    ];

    if (hasMap && variant.mapLocalFilename) {
      lines.push(
        `#EXT-X-MAP:URI="/api/streams/${streamId}/dvr/variant/${variant.id}/segments/${variant.mapLocalFilename}${query}"`,
      );
    }

    for (const seg of variant.segments) {
      if (seg.discontinuity) {
        lines.push('#EXT-X-DISCONTINUITY');
      }
      if (seg.programDateTimeIso) {
        lines.push(`#EXT-X-PROGRAM-DATE-TIME:${seg.programDateTimeIso}`);
      }
      lines.push(`#EXTINF:${seg.durationSec.toFixed(3)},`);
      lines.push(
        `/api/streams/${streamId}/dvr/variant/${variant.id}/segments/${seg.localFilename}${query}`,
      );
    }

    if (session.ended) {
      lines.push('#EXT-X-ENDLIST');
    }

    return `${lines.join('\n')}\n`;
  }

  resolveSegmentFile(
    streamId: string,
    variantId: number,
    filename: string,
  ):
    | { status: 'OK'; diskPath: string; contentType: string }
    | { status: 'EXPIRED' }
    | { status: 'NOT_FOUND' } {
    this.assertSafeId(streamId);
    if (!/^[a-zA-Z0-9._-]+$/.test(filename)) {
      return { status: 'NOT_FOUND' };
    }

    const session = this.sessions.get(streamId);
    if (!session) return { status: 'NOT_FOUND' };
    const variant = session.variants.find((v) => v.id === variantId);
    if (!variant) return { status: 'NOT_FOUND' };

    if (filename === variant.mapLocalFilename && variant.mapDiskPath) {
      if (fs.existsSync(variant.mapDiskPath)) {
        return {
          status: 'OK',
          diskPath: variant.mapDiskPath,
          contentType: 'video/mp4',
        };
      }
      return { status: 'EXPIRED' };
    }

    const seg = variant.segments.find((s) => s.localFilename === filename);
    if (seg) {
      if (fs.existsSync(seg.diskPath)) {
        return {
          status: 'OK',
          diskPath: seg.diskPath,
          contentType: seg.contentType,
        };
      }
      return { status: 'EXPIRED' };
    }

    // Detect requests for evicted historical segments cleanly so clients transition to DVR_EXPIRED.
    const seqMatch = /^seg_(\d+)\./.exec(filename);
    if (seqMatch && variant.segments.length > 0) {
      const requestedLocalSeq = Number(seqMatch[1]);
      const oldestRetainedLocalSeq = variant.nextLocalSeq - variant.segments.length;
      if (requestedLocalSeq < oldestRetainedLocalSeq) {
        return { status: 'EXPIRED' };
      }
    }

    return { status: 'NOT_FOUND' };
  }

  // ─── M3U8 Parsing Helpers (public for unit testing) ───────────────────────

  parseMasterPlaylist(
    content: string,
    baseUrl: string,
  ): ParsedMasterVariant[] {
    const lines = content.split(/\r?\n/);
    const variants: ParsedMasterVariant[] = [];

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;

      const attrs = line.substring('#EXT-X-STREAM-INF:'.length);
      const bwMatch = /BANDWIDTH=(\d+)/i.exec(attrs);
      const resMatch = /RESOLUTION=(\d+)x(\d+)/i.exec(attrs);
      const codecsMatch = /CODECS="([^"]+)"/i.exec(attrs);

      let uriLine = '';
      for (let j = i + 1; j < lines.length; j++) {
        const candidate = lines[j].trim();
        if (candidate && !candidate.startsWith('#')) {
          uriLine = candidate;
          i = j;
          break;
        }
      }
      if (!uriLine) continue;

      variants.push({
        bandwidth: bwMatch ? Number(bwMatch[1]) : 1500000,
        width: resMatch ? Number(resMatch[1]) : undefined,
        height: resMatch ? Number(resMatch[2]) : undefined,
        codecs: codecsMatch ? codecsMatch[1] : undefined,
        uri: new URL(uriLine, baseUrl).toString(),
      });
    }

    return variants.sort((a, b) => b.bandwidth - a.bandwidth);
  }

  parseMediaPlaylist(content: string, baseUrl: string): ParsedMediaPlaylist {
    const lines = content.split(/\r?\n/);
    let targetDurationSec = 4;
    let mediaSequence = 0;
    let isVodOrEnded = false;
    let currentMapUri: string | undefined;
    let pendingDiscontinuity = false;
    let pendingPdt: string | undefined;
    let pendingDurationSec: number | undefined;
    const segments: ParsedMediaSegment[] = [];

    for (const rawLine of lines) {
      const line = rawLine.trim();
      if (!line) continue;

      if (line.startsWith('#EXT-X-TARGETDURATION:')) {
        targetDurationSec =
          Number(line.substring('#EXT-X-TARGETDURATION:'.length)) || 4;
      } else if (line.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
        mediaSequence =
          Number(line.substring('#EXT-X-MEDIA-SEQUENCE:'.length)) || 0;
      } else if (line === '#EXT-X-DISCONTINUITY') {
        pendingDiscontinuity = true;
      } else if (line.startsWith('#EXT-X-PROGRAM-DATE-TIME:')) {
        pendingPdt = line.substring('#EXT-X-PROGRAM-DATE-TIME:'.length).trim();
      } else if (line.startsWith('#EXT-X-MAP:')) {
        const uriMatch = /URI="([^"]+)"/.exec(line);
        if (uriMatch?.[1]) {
          currentMapUri = new URL(uriMatch[1], baseUrl).toString();
        }
      } else if (line.startsWith('#EXTINF:')) {
        const durPart = line.substring('#EXTINF:'.length).split(',')[0];
        pendingDurationSec = Number(durPart) || targetDurationSec;
      } else if (line === '#EXT-X-ENDLIST') {
        isVodOrEnded = true;
      } else if (!line.startsWith('#')) {
        const resolvedUri = new URL(line, baseUrl).toString();
        segments.push({
          uri: resolvedUri,
          durationSec: pendingDurationSec ?? targetDurationSec,
          discontinuity: pendingDiscontinuity,
          programDateTimeIso: pendingPdt,
          mapUri: currentMapUri,
        });
        pendingDiscontinuity = false;
        pendingPdt = undefined;
        pendingDurationSec = undefined;
      }
    }

    return { targetDurationSec, mediaSequence, isVodOrEnded, segments };
  }

  // ─── Internal Polling & Segment Ring Buffer Management ────────────────────

  private pickPrimaryVariant(
    session?: DvrStreamSession,
  ): VariantBufferState | undefined {
    if (!session || session.variants.length === 0) return undefined;
    return (
      session.variants.find((v) => v.segments.length > 0) ?? session.variants[0]
    );
  }

  private async pollSession(session: DvrStreamSession): Promise<void> {
    if (session.ended || session.isPolling) return;
    session.isPolling = true;

    try {
      const rootRes = await fetch(session.upstreamUrl, {
        signal: AbortSignal.timeout(6000),
      });
      if (!rootRes.ok) {
        session.lastError = `HTTP ${rootRes.status}`;
        return;
      }
      const rootText = await rootRes.text();
      if (!rootText.includes('#EXTM3U')) {
        session.lastError = 'Upstream returned non-M3U8 payload';
        return;
      }

      if (session.variants.length === 0) {
        if (rootText.includes('#EXT-X-STREAM-INF:')) {
          const parsedVariants = this.parseMasterPlaylist(
            rootText,
            session.upstreamUrl,
          );
          const selected = parsedVariants.slice(0, this.maxVariants);
          for (let idx = 0; idx < selected.length; idx++) {
            const v = selected[idx];
            await this.initVariantState(session, idx, {
              label: v.height ? `${v.height}p` : `Quality ${idx + 1}`,
              bandwidth: v.bandwidth,
              width: v.width,
              height: v.height,
              codecs: v.codecs,
              upstreamUrl: v.uri,
            });
          }
        } else {
          await this.initVariantState(session, 0, {
            label: 'Source',
            bandwidth: 2000000,
            upstreamUrl: session.upstreamUrl,
          });
        }
      }

      for (const variant of session.variants) {
        const mediaText =
          variant.upstreamUrl === session.upstreamUrl
            ? rootText
            : await this.fetchPlaylistText(variant.upstreamUrl);
        if (!mediaText) continue;

        const parsed = this.parseMediaPlaylist(mediaText, variant.upstreamUrl);
        variant.targetDurationSec = parsed.targetDurationSec;

        for (let idx = 0; idx < parsed.segments.length; idx++) {
          const segMeta = parsed.segments[idx];
          if (variant.seenUris.has(segMeta.uri)) continue;

          await this.ingestSegment(
            session,
            variant,
            parsed.mediaSequence + idx,
            segMeta,
          );
        }

        this.trimVariantWindow(variant);
      }

      await this.enforceGlobalDiskBudget();
      session.lastUpdatedAtMs = Date.now();
      session.lastError = undefined;
    } catch (err: any) {
      session.lastError = err?.message ?? 'Poll error';
    } finally {
      session.isPolling = false;
    }
  }

  private async fetchPlaylistText(url: string): Promise<string | null> {
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(5000) });
      if (!res.ok) return null;
      return await res.text();
    } catch {
      return null;
    }
  }

  private async initVariantState(
    session: DvrStreamSession,
    id: number,
    meta: {
      label: string;
      bandwidth: number;
      width?: number;
      height?: number;
      codecs?: string;
      upstreamUrl: string;
    },
  ): Promise<void> {
    const variantDir = path.join(this.baseDir, session.streamId, `v${id}`);
    await fs.promises.mkdir(variantDir, { recursive: true });
    session.variants.push({
      id,
      label: meta.label,
      bandwidth: meta.bandwidth,
      width: meta.width,
      height: meta.height,
      codecs: meta.codecs,
      upstreamUrl: meta.upstreamUrl,
      targetDurationSec: 4,
      mediaSequence: 0,
      nextLocalSeq: 0,
      cumulativeDurationSec: 0,
      segments: [],
      seenUris: new Set<string>(),
    });
  }

  private async ingestSegment(
    session: DvrStreamSession,
    variant: VariantBufferState,
    upstreamSeq: number,
    meta: ParsedMediaSegment,
  ): Promise<void> {
    const variantDir = path.join(this.baseDir, session.streamId, `v${variant.id}`);

    // Download init segment (#EXT-X-MAP) if new
    if (meta.mapUri && meta.mapUri !== variant.mapUpstreamUri) {
      try {
        const mapRes = await fetch(meta.mapUri, {
          signal: AbortSignal.timeout(6000),
        });
        if (mapRes.ok) {
          const mapBuf = Buffer.from(await mapRes.arrayBuffer());
          const mapFilename = `init_${variant.nextLocalSeq}.mp4`;
          const mapDiskPath = path.join(variantDir, mapFilename);
          await fs.promises.writeFile(mapDiskPath, mapBuf);
          variant.mapUpstreamUri = meta.mapUri;
          variant.mapLocalFilename = mapFilename;
          variant.mapDiskPath = mapDiskPath;
        }
      } catch {
        // Non-fatal: segment may still succeed on retry
      }
    }

    const segRes = await fetch(meta.uri, { signal: AbortSignal.timeout(8000) });
    if (!segRes.ok) return;

    const bytes = Buffer.from(await segRes.arrayBuffer());
    if (bytes.length === 0) return;

    const urlPath = new URL(meta.uri).pathname.toLowerCase();
    const isMp4 = urlPath.endsWith('.m4s') || urlPath.endsWith('.mp4');
    const ext = isMp4 ? '.m4s' : '.ts';
    const contentType = isMp4 ? 'video/mp4' : 'video/mp2t';

    const localSeq = variant.nextLocalSeq++;
    const localFilename = `seg_${String(localSeq).padStart(7, '0')}${ext}`;
    const diskPath = path.join(variantDir, localFilename);
    await fs.promises.writeFile(diskPath, bytes);

    const startOffsetSec = variant.cumulativeDurationSec;
    const endOffsetSec = startOffsetSec + meta.durationSec;
    variant.cumulativeDurationSec = endOffsetSec;

    if (variant.segments.length === 0) {
      variant.mediaSequence = upstreamSeq;
    }

    variant.segments.push({
      seq: upstreamSeq,
      localFilename,
      diskPath,
      upstreamUri: meta.uri,
      durationSec: meta.durationSec,
      startOffsetSec,
      endOffsetSec,
      programDateTimeIso:
        meta.programDateTimeIso ??
        new Date(session.startedAtMs + startOffsetSec * 1000).toISOString(),
      discontinuity: meta.discontinuity,
      byteLength: bytes.length,
      contentType,
      mapLocalFilename: variant.mapLocalFilename,
    });
    variant.seenUris.add(meta.uri);
  }

  private trimVariantWindow(variant: VariantBufferState): void {
    while (variant.segments.length > 1) {
      const oldest = variant.segments[0];
      const newest = variant.segments[variant.segments.length - 1];
      const span = newest.endOffsetSec - oldest.startOffsetSec;
      if (span <= this.windowSeconds) break;
      this.evictOldestSegment(variant);
    }
  }

  private evictOldestSegment(variant: VariantBufferState): void {
    const removed = variant.segments.shift();
    if (!removed) return;
    variant.mediaSequence += 1;
    // Retain seenUri check bounded to keep memory small while avoiding duplicates
    if (variant.seenUris.size > 5000) {
      variant.seenUris.delete(removed.upstreamUri);
    }
    void fs.promises.rm(removed.diskPath, { force: true }).catch(() => {});
  }

  private async enforceGlobalDiskBudget(): Promise<void> {
    let totalBytes = 0;
    const allVariants: VariantBufferState[] = [];
    for (const session of this.sessions.values()) {
      for (const v of session.variants) {
        allVariants.push(v);
        for (const s of v.segments) {
          totalBytes += s.byteLength;
        }
      }
    }

    while (totalBytes > this.maxDiskBytes) {
      let evictedAny = false;
      for (const v of allVariants) {
        if (v.segments.length > 10) {
          const headBytes = v.segments[0].byteLength;
          this.evictOldestSegment(v);
          totalBytes -= headBytes;
          evictedAny = true;
          if (totalBytes <= this.maxDiskBytes) break;
        }
      }
      if (!evictedAny) break;
    }
  }

  private assertSafeId(value: string): void {
    if (!/^[a-zA-Z0-9_-]+$/.test(value)) {
      throw new Error(`Invalid DVR identifier: ${value}`);
    }
  }
}

function sessionCleanup(session: DvrStreamSession): NodeJS.Timeout {
  return session.cleanupTimer!;
}
