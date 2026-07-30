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
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiParam, ApiQuery } from '@nestjs/swagger';
import { LiveStreamingService } from './live-streaming.service.js';
import { CreateStreamDto } from './dto/create-stream.dto.js';
import { UpdateStreamDto } from './dto/update-stream.dto.js';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { OptionalJwtAuthGuard } from '../../common/guards/optional-jwt-auth.guard.js';

@ApiTags('Live Streaming')
@Controller('video-channels/:channelId/streams')
export class LiveStreamingController {
  constructor(private readonly liveStreamingService: LiveStreamingService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new live stream (Draft or Scheduled)' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
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
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getChannelStreams(
    @CurrentUser('sub') userId: string | undefined,
    @Param('channelId') channelId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.liveStreamingService.getChannelStreams(userId, channelId, page, limit);
  }

  @Post('key/regenerate')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Generate or regenerate RTMP stream key' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  async regenerateStreamKey(
    @CurrentUser('sub') userId: string,
    @Param('channelId') channelId: string,
  ) {
    return this.liveStreamingService.generateStreamKey(userId, channelId);
  }
}

@ApiTags('Live Streaming')
@Controller('streams')
export class StreamsController {
  constructor(private readonly liveStreamingService: LiveStreamingService) {}

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
  @ApiOperation({ summary: 'Delete/Cancel a stream' })
  @ApiParam({ name: 'id', description: 'Stream ID' })
  async deleteStream(
    @CurrentUser('sub') userId: string,
    @Param('id') streamId: string,
  ) {
    return this.liveStreamingService.deleteStream(userId, streamId);
  }
}
