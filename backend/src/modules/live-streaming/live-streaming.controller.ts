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
} from '@nestjs/common';
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
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.liveStreamingService.getChannelStreams(
      userId,
      channelId,
      page,
      limit,
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
}

// ─── Global Stream Controller ───────────────────────────────────────────────

@ApiTags('Live Streaming')
@Controller('streams')
export class StreamsController {
  constructor(private readonly liveStreamingService: LiveStreamingService) {}

  @Get('live')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'List all currently live public streams' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getLiveStreams(
    @CurrentUser('sub') userId: string | undefined,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.liveStreamingService.getLiveStreams(userId, page, limit);
  }

  @Get('scheduled')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'List all upcoming scheduled public streams' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getScheduledStreams(
    @CurrentUser('sub') userId: string | undefined,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.liveStreamingService.getScheduledStreams(userId, page, limit);
  }

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

  @Post('rtmp/webhook/validate-key')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Internal RTMP server webhook: validate stream key',
  })
  async validateStreamKey(@Body('key') key: string) {
    if (!key) return { valid: false };
    const result = await this.liveStreamingService.validateStreamKey(key);
    return { valid: result.streamId !== null, ...result };
  }
}
