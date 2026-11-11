import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Query,
  ParseIntPipe,
  DefaultValuePipe,
  HttpCode,
  HttpStatus,
  BadRequestException,
  Res,
  NotFoundException,
  GoneException,
} from '@nestjs/common';
import type { Response } from 'express';
import * as fs from 'fs';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
  ApiResponse,
} from '@nestjs/swagger';
import { LiveStreamingService } from './live-streaming.service.js';
import { CreateStreamDto } from './dto/create-stream.dto.js';
import { UpdateStreamDto } from './dto/update-stream.dto.js';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { OptionalJwtAuthGuard } from '../../common/guards/optional-jwt-auth.guard.js';
import { Public } from '../../common/decorators/public.decorator.js';

// ─── Channel-scoped Stream Controller ──────────────────────────────────────

@ApiTags('Live Streaming')
@Controller('video-channels/:channelId/streams')
export class LiveStreamingController {
  constructor(private readonly liveStreamingService: LiveStreamingService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new live stream (Draft or Scheduled)' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiResponse({ status: 201, description: 'Stream created successfully' })
  async createStream(
    @CurrentUser('sub') userId: string,
    @Param('channelId') channelId: string,
    @Body() dto: CreateStreamDto,
  ) {
    return this.liveStreamingService.createStream(userId, channelId, dto);
  }

  @Get()
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List streams for a channel' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'limit', required: false, type: Number, example: 20 })
  async getChannelStreams(
    @CurrentUser('sub') userId: string | undefined,
    @Param('channelId') channelId: string,
    @Query('page', new DefaultValuePipe(1), new ParseIntPipe({ optional: true })) page: number,
    @Query('limit', new DefaultValuePipe(20), new ParseIntPipe({ optional: true })) limit: number,
  ) {
    return this.liveStreamingService.getChannelStreams(
      userId,
      channelId,
      page ?? 1,
      limit ?? 20,
    );
  }

  @Get('key')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Get stream key info for the channel (key prefix only, not the full key)',
  })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  async getStreamKey(
    @CurrentUser('sub') userId: string,
    @Param('channelId') channelId: string,
  ) {
    return this.liveStreamingService.getStreamKey(userId, channelId);
  }

  @Post('key/regenerate')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Generate or regenerate RTMP stream key (returns raw key ONCE)',
  })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  async regenerateStreamKey(
    @CurrentUser('sub') userId: string,
    @Param('channelId') channelId: string,
  ) {
    return this.liveStreamingService.generateStreamKey(userId, channelId);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete/Cancel a stream in this channel' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async deleteStream(
    @CurrentUser('sub') userId: string,
    @Param('id') streamId: string,
  ) {
    return this.liveStreamingService.deleteStream(userId, streamId);
  }
}

// ─── Global Stream Controller ───────────────────────────────────────────────

@ApiTags('Live Streaming')
@Controller('streams')
export class StreamsController {
  constructor(private readonly liveStreamingService: LiveStreamingService) {}

  @Public()
  @Get('live')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'List all currently live public streams' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'category', required: false, type: String })
  async getLiveStreams(
    @CurrentUser('sub') userId: string | undefined,
    @Query('page', new DefaultValuePipe(1), new ParseIntPipe({ optional: true })) page: number,
    @Query('limit', new DefaultValuePipe(20), new ParseIntPipe({ optional: true })) limit: number,
    @Query('category') category?: string,
  ) {
    return this.liveStreamingService.getLiveStreams(userId, page ?? 1, limit ?? 20, category);
  }

  @Public()
  @Get('scheduled')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'List all upcoming scheduled public streams' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'category', required: false, type: String })
  async getScheduledStreams(
    @CurrentUser('sub') userId: string | undefined,
    @Query('page', new DefaultValuePipe(1), new ParseIntPipe({ optional: true })) page: number,
    @Query('limit', new DefaultValuePipe(20), new ParseIntPipe({ optional: true })) limit: number,
    @Query('category') category?: string,
  ) {
    return this.liveStreamingService.getScheduledStreams(userId, page ?? 1, limit ?? 20, category);
  }


  @Public()
  @Get('user/:userId')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List all streams created by a user' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getUserStreams(
    @CurrentUser('sub') currentUserId: string | undefined,
    @Param('userId') targetUserId: string,
    @Query('page', new DefaultValuePipe(1), new ParseIntPipe({ optional: true })) page: number,
    @Query('limit', new DefaultValuePipe(50), new ParseIntPipe({ optional: true })) limit: number,
  ) {
    return this.liveStreamingService.getUserStreams(
      currentUserId,
      targetUserId,
      page ?? 1,
      limit ?? 50,
    );
  }

  @Public()
  @Get(':id')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get stream details by ID' })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async getStreamById(
    @CurrentUser('sub') userId: string | undefined,
    @Param('id') streamId: string,
  ) {
    return this.liveStreamingService.getStreamById(userId, streamId);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update stream metadata' })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async updateStream(
    @CurrentUser('sub') userId: string,
    @Param('id') streamId: string,
    @Body() dto: UpdateStreamDto,
  ) {
    return this.liveStreamingService.updateStream(userId, streamId, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete/Cancel a stream' })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async deleteStream(
    @CurrentUser('sub') userId: string,
    @Param('id') streamId: string,
  ) {
    return this.liveStreamingService.deleteStream(userId, streamId);
  }

  @Post(':id/prepare')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Provision/activate ingest credentials without marking DB status LIVE yet',
  })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async prepareIngest(
    @CurrentUser('sub') userId: string,
    @Param('id') streamId: string,
  ) {
    return this.liveStreamingService.prepareIngest(userId, streamId);
  }

  @Post(':id/abort-start')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Roll back a failed or aborted broadcast attempt so streams never stick in LIVE',
  })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async abortStart(
    @CurrentUser('sub') userId: string,
    @Param('id') streamId: string,
    @Body() body: { reason?: string },
  ) {
    return this.liveStreamingService.abortStart(userId, streamId, body?.reason);
  }

  @Public()
  @Get(':id/dvr/timeline')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Get real server-side DVR sliding window metadata (retention, live edge, variants)',
  })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async getDvrTimeline(
    @CurrentUser('sub') userId: string | undefined,
    @Param('id') streamId: string,
  ) {
    return this.liveStreamingService.getDvrTimeline(userId, streamId);
  }

  @Public()
  @Get(':id/dvr/master.m3u8')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'Serve DVR-enabled HLS master playlist' })
  async getDvrMasterPlaylist(
    @CurrentUser('sub') userId: string | undefined,
    @Param('id') streamId: string,
    @Query('dvrToken') dvrToken: string | undefined,
    @Res() res: Response,
  ) {
    const m3u8 = await this.liveStreamingService.getDvrMasterPlaylist(
      userId,
      streamId,
      dvrToken,
    );
    if (!m3u8) {
      throw new NotFoundException('DVR master playlist not yet ready');
    }
    res.setHeader('Content-Type', 'application/vnd.apple.mpegurl; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.send(m3u8);
  }

  @Public()
  @Get(':id/dvr/playlist.m3u8')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'Serve primary variant DVR HLS playlist' })
  async getDvrDefaultVariantPlaylist(
    @CurrentUser('sub') userId: string | undefined,
    @Param('id') streamId: string,
    @Query('dvrToken') dvrToken: string | undefined,
    @Res() res: Response,
  ) {
    return this.getDvrVariantPlaylist(userId, streamId, 0, dvrToken, res);
  }

  @Public()
  @Get(':id/dvr/variant/:variantId/playlist.m3u8')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'Serve variant DVR HLS sliding playlist' })
  async getDvrVariantPlaylist(
    @CurrentUser('sub') userId: string | undefined,
    @Param('id') streamId: string,
    @Param('variantId', ParseIntPipe) variantId: number,
    @Query('dvrToken') dvrToken: string | undefined,
    @Res() res: Response,
  ) {
    const m3u8 = await this.liveStreamingService.getDvrVariantPlaylist(
      userId,
      streamId,
      variantId,
      dvrToken,
    );
    if (!m3u8) {
      throw new NotFoundException('DVR variant playlist not yet ready');
    }
    res.setHeader('Content-Type', 'application/vnd.apple.mpegurl; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.send(m3u8);
  }

  @Public()
  @Get(':id/dvr/variant/:variantId/segments/:filename')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'Serve retained DVR HLS media segment (.ts / .m4s)' })
  async getDvrSegment(
    @CurrentUser('sub') userId: string | undefined,
    @Param('id') streamId: string,
    @Param('variantId', ParseIntPipe) variantId: number,
    @Param('filename') filename: string,
    @Query('dvrToken') dvrToken: string | undefined,
    @Res() res: Response,
  ) {
    const result = await this.liveStreamingService.getDvrSegmentFile(
      userId,
      streamId,
      variantId,
      filename,
      dvrToken,
    );
    if (result.status === 'EXPIRED') {
      throw new GoneException({
        code: 'DVR_SEGMENT_EXPIRED',
        message: 'Requested segment is older than the retained DVR window',
      });
    }
    if (result.status !== 'OK') {
      throw new NotFoundException('DVR segment not found');
    }

    res.setHeader('Content-Type', result.contentType);
    res.setHeader('Cache-Control', 'public, max-age=300');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    const stream = fs.createReadStream(result.diskPath);
    stream.on('error', () => {
      if (!res.headersSent) {
        res.status(HttpStatus.GONE).json({
          code: 'DVR_SEGMENT_EXPIRED',
          message: 'Segment is no longer available in DVR buffer',
        });
      } else {
        res.end();
      }
    });
    stream.pipe(res);
  }

  @Get(':id/ingest-status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Inspect live ingest state across DB, Cloudinary live_streams API, and MediaMTX',
  })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async getIngestStatus(
    @CurrentUser('sub') userId: string,
    @Param('id') streamId: string,
  ) {
    return this.liveStreamingService.getIngestStatus(userId, streamId);
  }

  @Get(':id/whip-session')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Get WHIP ingest endpoint for browser WebRTC broadcasting (Web Live Studio)',
  })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  @ApiResponse({
    status: 200,
    description: 'Returns whipUrl, streamKey, and rtmpUrl for WebRTC ingest',
  })
  async getWhipSession(
    @CurrentUser('sub') userId: string,
    @Param('id') streamId: string,
  ) {
    return this.liveStreamingService.getWhipSession(userId, streamId);
  }

  @Post(':id/go-live')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Start a live stream (set status to LIVE)' })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async startStream(
    @CurrentUser('sub') userId: string,
    @Param('id') streamId: string,
  ) {
    return this.liveStreamingService.startStream(userId, streamId);
  }

  @Post(':id/end')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'End a live stream (set status to ENDED)' })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async endStream(
    @CurrentUser('sub') userId: string,
    @Param('id') streamId: string,
  ) {
    return this.liveStreamingService.endStream(userId, streamId);
  }

  @Post(':id/publish-vod')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Publish VOD from stream recording' })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async publishVod(
    @CurrentUser('sub') userId: string,
    @Param('id') streamId: string,
  ) {
    return this.liveStreamingService.publishVod(userId, streamId);
  }

  @Public()
  @Post('rtmp/webhook/on_publish')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'RTMP webhook: Triggered when a stream starts publishing (SRS / Nginx-RTMP)',
  })
  async onPublish(@Body() body: any) {
    // SRS sends 'stream', Nginx-RTMP sends 'name'
    const streamKey = body.stream || body.name;
    if (!streamKey) {
      throw new BadRequestException('Stream key missing');
    }
    await this.liveStreamingService.handleRtmpOnPublish(streamKey);
    return { code: 0, message: 'OK' }; // code 0 allows stream in SRS, HTTP 200 allows in Nginx
  }

  @Public()
  @Post('rtmp/webhook/on_done')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'RTMP webhook: Triggered when a stream ends (SRS / Nginx-RTMP / Cloudinary)',
  })
  async onDone(@Body() body: any) {
    if (body.public_id || body.notification_type) {
      await this.liveStreamingService.handleCloudinaryWebhook(body);
      return { code: 0, message: 'OK' };
    }
    const streamKey = body.stream || body.name;
    if (!streamKey) {
      return { code: 0, message: 'OK' };
    }
    await this.liveStreamingService.handleRtmpOnDone(streamKey);
    return { code: 0, message: 'OK' };
  }

  @Public()
  @Post('cloudinary/webhook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Cloudinary notification webhook (archive / upload / live events)',
  })
  async handleCloudinaryWebhook(@Body() body: any) {
    await this.liveStreamingService.handleCloudinaryWebhook(body);
    return { status: 'ok' };
  }
}
