// src/modules/video-processing/video-processing.controller.ts
import { Controller, Post, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiResponse, ApiTags } from '@nestjs/swagger';
import { VideoProcessingService } from './video-processing.service.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { AppRole } from '../../common/constants/roles.js';

@ApiTags('Video Processing')
@ApiBearerAuth()
@Controller('video-processing')
export class VideoProcessingController {
  constructor(private readonly processingService: VideoProcessingService) {}

  @Post(':videoId/reprocess')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @ApiOperation({ summary: 'Manually trigger video re-processing (Admin only)' })
  @ApiParam({ name: 'videoId', description: 'ID of video to transcode' })
  @ApiResponse({ status: 200, description: 'Processing triggered' })
  async triggerProcessing(@Param('videoId') videoId: string) {
    // Synchronously trigger processing fallback for admin manual request
    void this.processingService.processVideo({
      videoId,
      sourceFilePath: `videos/${videoId}/raw.mp4`,
      storageKey: `videos/${videoId}/raw.mp4`,
    });

    return { message: `Video re-processing initiated for video ${videoId}` };
  }
}
