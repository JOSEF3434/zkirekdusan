// src/modules/video-playlists/video-playlists.controller.ts
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { VideoPlaylistsService } from './video-playlists.service.js';
import {
  CreatePlaylistDto,
  AddPlaylistItemDto,
} from './dto/create-playlist.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Video Playlists')
@ApiBearerAuth()
@Controller('video-playlists')
export class VideoPlaylistsController {
  constructor(private readonly service: VideoPlaylistsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a video playlist' })
  @ApiResponse({ status: 201, description: 'Playlist created successfully' })
  async createPlaylist(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreatePlaylistDto,
  ) {
    return this.service.create(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get current user playlists' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getMyPlaylists(
    @CurrentUser('sub') userId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.service.findByUser(userId, +page, +limit);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get playlist by ID' })
  @ApiParam({ name: 'id', description: 'Playlist ID' })
  async getPlaylist(@Param('id') id: string) {
    return this.service.findById(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update playlist details' })
  @ApiParam({ name: 'id', description: 'Playlist ID' })
  async updatePlaylist(
    @Param('id') id: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: Partial<CreatePlaylistDto>,
  ) {
    return this.service.update(id, userId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete playlist' })
  @ApiParam({ name: 'id', description: 'Playlist ID' })
  async deletePlaylist(
    @Param('id') id: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.delete(id, userId);
  }

  @Post(':id/items')
  @ApiOperation({ summary: 'Add video to playlist' })
  @ApiParam({ name: 'id', description: 'Playlist ID' })
  async addItem(
    @Param('id') id: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: AddPlaylistItemDto,
  ) {
    return this.service.addItem(id, userId, dto);
  }

  @Delete(':id/items/:videoId')
  @ApiOperation({ summary: 'Remove video from playlist' })
  @ApiParam({ name: 'id', description: 'Playlist ID' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async removeItem(
    @Param('id') id: string,
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.service.removeItem(id, videoId, userId);
  }
}
