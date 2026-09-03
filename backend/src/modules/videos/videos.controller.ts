// src/modules/videos/videos.controller.ts
import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Logger,
  NotFoundException,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { VideosService } from './videos.service.js';
import { UploadVideoDto } from './dto/upload-video.dto.js';
import { UpdateVideoDto } from './dto/update-video.dto.js';
import {
  VideoListResponseDto,
  VideoResponseDto,
} from './dto/video-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { VideoReportReason, VideoStatus } from '@prisma/client';
import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { UploadsService } from '../uploads/uploads.service.js';
import { Type } from 'class-transformer';

class WatchProgressBodyDto {
  @ApiPropertyOptional({
    example: 125.5,
    description: 'Current position in seconds',
  })
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  watchedSeconds!: number;
}

class ReportVideoDto {
  @ApiPropertyOptional({ enum: VideoReportReason })
  @IsEnum(VideoReportReason)
  reason!: VideoReportReason;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  details?: string;
}

@ApiTags('Videos')
@ApiBearerAuth()
@Controller('video-channels/:channelId/videos')
export class VideosController {
  private readonly logger = new Logger(VideosController.name);

  constructor(
    private readonly videosService: VideosService,
    private readonly uploadsService: UploadsService,
  ) {}

  @Post()
  @ApiOperation({
    summary: 'Initiate a video upload',
    description:
      'Creates a video record. Must be followed by POST /videos/:id/file to attach the actual video file. Requires GROUP_ADMIN, MODERATOR, or channel-specific upload permission.',
  })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiResponse({ status: 201, type: VideoResponseDto })
  @ApiResponse({ status: 403, description: 'Insufficient upload permissions' })
  initiateUpload(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: UploadVideoDto,
  ): Promise<VideoResponseDto> {
    return this.videosService.initiateUpload(channelId, userId, dto) as any;
  }

  @Post(':videoId/file')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Upload video file and trigger processing',
    description:
      'Uploads the actual video file, attaches it to the video record, and queues background transcoding via BullMQ. Supports large files up to 4GB.',
  })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiParam({ name: 'videoId', description: 'Video ID from initiation step' })
  @ApiBody({
    description: 'Video file upload (multipart/form-data)',
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  async attachFile(
    @Param('channelId') channelId: string,
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('No file provided in multipart request');
    }

    this.logger.log(
      `[attachFile] videoId=${videoId} channelId=${channelId} userId=${userId} ` +
        `filename=${file.originalname} mimeType=${file.mimetype} size=${file.size}`,
    );

    // Get the video's group ID for file ownership — CRITICAL: use findRaw to avoid DTO mapping issues
    const video = await this.videosService.findByIdRaw(videoId);
    if (!video) {
      throw new NotFoundException(`Video ${videoId} not found`);
    }

    const groupId = video.videoChannel?.groupId;
    if (!groupId) {
      this.logger.error(
        `[attachFile] videoId=${videoId} has no videoChannel.groupId — channel may be deleted`,
      );
      throw new BadRequestException(
        'Video channel has no associated group. Cannot attach file.',
      );
    }

    this.logger.log(
      `[attachFile] Uploading file to group=${groupId} via storage provider`,
    );

    // Upload the file to storage
    const uploadedFile = await this.uploadsService.uploadGroupFile(
      groupId,
      userId,
      file,
    );

    this.logger.log(
      `[attachFile] File stored: fileId=${uploadedFile.id} url=${uploadedFile.url}`,
    );

    // Attach the file to the video and queue transcoding
    return this.videosService.attachSourceFile(videoId, uploadedFile.id, userId);
  }

  @Post(':videoId/thumbnail')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Upload a custom thumbnail for a video',
    description: 'Uploads an image file and sets it as the video thumbnail.',
  })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  @ApiBody({
    description: 'Thumbnail image file (multipart/form-data)',
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  async uploadThumbnail(
    @Param('channelId') channelId: string,
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('No thumbnail file provided');
    }

    const video = await this.videosService.findByIdRaw(videoId);
    if (!video) throw new NotFoundException(`Video ${videoId} not found`);

    const groupId = video.videoChannel?.groupId;
    if (!groupId) throw new BadRequestException('Video has no associated group');

    const uploadedFile = await this.uploadsService.uploadGroupFile(
      groupId,
      userId,
      file,
    );

    return this.videosService.setThumbnail(videoId, uploadedFile.url, userId);
  }

  @Get()
  @ApiOperation({ summary: 'List videos in a channel' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({
    name: 'cursor',
    required: false,
    description: 'Cursor for pagination',
  })
  @ApiQuery({ name: 'status', required: false, enum: VideoStatus })
  @ApiQuery({ name: 'search', required: false })
  @ApiResponse({ status: 200, type: VideoListResponseDto })
  listVideos(
    @Param('channelId') channelId: string,
    @CurrentUser('sub') userId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('cursor') cursor?: string,
    @Query('status') status?: VideoStatus,
    @Query('search') search?: string,
  ): Promise<VideoListResponseDto> {
    return this.videosService.findByChannel(channelId, userId, {
      page: +page,
      limit: +limit,
      cursor,
      status,
      search,
    }) as any;
  }

  @Get(':videoId')
  @ApiOperation({ summary: 'Get video details by ID' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  @ApiResponse({ status: 200, type: VideoResponseDto })
  getVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<VideoResponseDto> {
    return this.videosService.findById(videoId, userId) as any;
  }

  @Patch(':videoId')
  @ApiOperation({ summary: 'Update video metadata' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  @ApiResponse({ status: 200, type: VideoResponseDto })
  updateVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateVideoDto,
  ): Promise<VideoResponseDto> {
    return this.videosService.update(videoId, userId, dto) as any;
  }

  @Post(':videoId/publish')
  @ApiOperation({
    summary: 'Publish a video (set visibility to PUBLIC)',
    description: 'Video must be in READY status before publishing.',
  })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async publishVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.publish(videoId, userId);
  }

  @Delete(':videoId')
  @ApiOperation({ summary: 'Delete (soft-delete) a video' })
  @ApiParam({ name: 'channelId', description: 'Video Channel ID' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async deleteVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.deleteVideo(videoId, userId);
  }

  @Post(':videoId/like')
  @ApiOperation({ summary: 'Like a video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async likeVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.likeVideo(videoId, userId, true);
  }

  @Post(':videoId/dislike')
  @ApiOperation({ summary: 'Dislike a video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async dislikeVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.likeVideo(videoId, userId, false);
  }

  @Delete(':videoId/like')
  @ApiOperation({ summary: 'Remove like/dislike from a video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async removeLike(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.removeLike(videoId, userId);
  }

  @Get(':videoId/like-status')
  @ApiOperation({ summary: 'Check current user like/dislike status on video' })
  async getLikeStatus(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.getUserLikeStatus(videoId, userId);
  }

  @Patch(':videoId/progress')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update watch progress for a video',
    description:
      'Syncs playback position across devices. Auto-marks as completed at ≥90%.',
  })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async updateProgress(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
    @Body() body: WatchProgressBodyDto,
  ) {
    return this.videosService.updateWatchProgress(
      videoId,
      userId,
      body.watchedSeconds,
    );
  }

  @Get(':videoId/progress')
  @ApiOperation({ summary: 'Get user watch progress on a video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async getProgress(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.getWatchProgress(videoId, userId);
  }

  @Post(':videoId/bookmark')
  @ApiOperation({ summary: 'Bookmark (save) a video for later' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async bookmarkVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.bookmarkVideo(videoId, userId);
  }

  @Delete(':videoId/bookmark')
  @ApiOperation({ summary: 'Remove video bookmark' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async removeBookmark(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.removeBookmark(videoId, userId);
  }

  @Get(':videoId/recommended')
  @ApiOperation({ summary: 'Get recommended videos based on current video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  @ApiQuery({ name: 'limit', required: false, example: 10 })
  async getRecommended(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
    @Query('limit') limit = 10,
  ) {
    return this.videosService.getRecommended(videoId, userId, +limit);
  }

  @Post(':videoId/report')
  @ApiOperation({ summary: 'Report a video for moderation' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async reportVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: ReportVideoDto,
  ) {
    return this.videosService.reportVideo(
      videoId,
      userId,
      dto.reason,
      dto.details,
    );
  }
}

// ─── Public/discovery endpoints (/api/videos) ───────────────────────────────

@ApiTags('Videos')
@ApiBearerAuth()
@Controller('videos')
export class VideosPublicController {
  constructor(private readonly videosService: VideosService) {}

  @Get()
  @ApiOperation({ summary: 'Get videos by author or discovery query' })
  @ApiQuery({ name: 'authorId', required: false })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'isStream', required: false, example: 'false' })
  async getVideos(
    @Query('authorId') authorId?: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('isStream') isStream?: string,
  ) {
    if (authorId) {
      const streamFilter =
        isStream === 'true' ? true : isStream === 'false' ? false : undefined;
      return this.videosService.findByUser(authorId, {
        page: +page,
        limit: +limit,
        isStream: streamFilter,
      });
    }
    return this.videosService.getLatest(+page, +limit);
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get videos uploaded by a specific user' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'isStream', required: false, example: 'false' })
  async getUserVideos(
    @Param('userId') userId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('isStream') isStream?: string,
  ) {
    const streamFilter =
      isStream === 'true' ? true : isStream === 'false' ? false : undefined;
    return this.videosService.findByUser(userId, {
      page: +page,
      limit: +limit,
      isStream: streamFilter,
    });
  }

  @Get('latest')
  @ApiOperation({
    summary: 'Get latest public videos sorted by upload date (newest first)',
  })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getLatest(@Query('page') page = 1, @Query('limit') limit = 20) {
    return this.videosService.getLatest(+page, +limit);
  }

  @Get('trending')
  @ApiOperation({
    summary: 'Get trending videos (last 7 days, sorted by views)',
  })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getTrending(@Query('limit') limit = 20) {
    return this.videosService.getTrending(+limit);
  }

  @Get('search')
  @ApiOperation({ summary: 'Search public videos' })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'category', required: false })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async searchVideos(
    @Query('search') search?: string,
    @Query('category') category?: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.videosService.searchVideos({
      search,
      category,
      page: +page,
      limit: +limit,
    });
  }

  @Get('slug/:slug')
  @ApiOperation({ summary: 'Get video by SEO-friendly slug' })
  @ApiParam({ name: 'slug', example: 'introduction-to-nestjs-a1b2c3d4' })
  async getBySlug(
    @Param('slug') slug: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.findBySlug(slug, userId);
  }

  @Get('watch-history')
  @ApiOperation({
    summary: 'Get current user watch history (continue watching)',
  })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getWatchHistory(
    @CurrentUser('sub') userId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.videosService.getWatchHistory(userId, +page, +limit);
  }

  @Delete('watch-history/:videoId')
  @ApiOperation({ summary: 'Remove a video from watch history' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async removeFromWatchHistory(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.removeFromWatchHistory(videoId, userId);
  }

  @Delete('watch-history')
  @ApiOperation({ summary: 'Clear all watch history' })
  async clearWatchHistory(@CurrentUser('sub') userId: string) {
    return this.videosService.clearWatchHistory(userId);
  }

  @Get('bookmarks')
  @ApiOperation({ summary: 'Get current user bookmarked videos (watch later)' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getBookmarks(
    @CurrentUser('sub') userId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.videosService.getBookmarks(userId, +page, +limit);
  }

  @Post(':videoId/bookmark')
  @ApiOperation({ summary: 'Bookmark a video (Save to Watch Later)' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async bookmarkVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.bookmarkVideo(videoId, userId);
  }

  @Delete(':videoId/bookmark')
  @ApiOperation({ summary: 'Remove bookmark from a video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async removeBookmark(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.removeBookmark(videoId, userId);
  }

  @Get('liked')
  @ApiOperation({ summary: 'Get current user liked videos' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getLikedVideos(
    @CurrentUser('sub') userId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.videosService.getLikedVideos(userId, +page, +limit);
  }

  // ─── Direct video ID endpoints ─────────────────────────────────────────────

  @Get(':videoId')
  @ApiOperation({ summary: 'Get video details by ID' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  @ApiResponse({ status: 200, type: VideoResponseDto })
  async getVideoById(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ): Promise<VideoResponseDto> {
    return this.videosService.findById(videoId, userId) as any;
  }

  @Patch(':videoId')
  @ApiOperation({ summary: 'Update video details' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async updateVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateVideoDto,
  ) {
    return this.videosService.updateVideo(videoId, userId, dto);
  }

  @Delete(':videoId')
  @ApiOperation({ summary: 'Delete video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async deleteVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.deleteVideo(videoId, userId);
  }

  @Get(':videoId/status')
  @ApiOperation({ summary: 'Get video processing status' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async getVideoStatus(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.findById(videoId, userId);
  }

  @Patch(':videoId/progress')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update watch progress for a video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async updateProgress(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
    @Body() body: WatchProgressBodyDto,
  ) {
    return this.videosService.updateWatchProgress(
      videoId,
      userId,
      body.watchedSeconds,
    );
  }

  @Post(':videoId/like')
  @ApiOperation({ summary: 'Like a video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async likeVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.likeVideo(videoId, userId, true);
  }

  @Post(':videoId/dislike')
  @ApiOperation({ summary: 'Dislike a video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async dislikeVideo(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.likeVideo(videoId, userId, false);
  }

  @Delete(':videoId/like')
  @ApiOperation({ summary: 'Remove like/dislike from a video' })
  @ApiParam({ name: 'videoId', description: 'Video ID' })
  async removeLike(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.removeLike(videoId, userId);
  }

  @Get(':videoId/like-status')
  @ApiOperation({ summary: 'Check current user like/dislike status on video' })
  async getLikeStatus(
    @Param('videoId') videoId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.videosService.getUserLikeStatus(videoId, userId);
  }
}
