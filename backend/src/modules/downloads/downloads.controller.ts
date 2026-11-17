// src/modules/downloads/downloads.controller.ts
import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Res,
  Req,
  NotFoundException,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { DownloadsService } from './downloads.service.js';
import {
  RequestVideoDownloadDto,
  RequestFileDownloadDto,
  RequestPostDownloadDto,
  DownloadTokenResponseDto,
} from './dto/request-download.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import type { Response, Request } from 'express';
import fs from 'fs';

@ApiTags('Downloads')
@ApiBearerAuth()
@Controller('downloads')
export class DownloadsController {
  constructor(private readonly service: DownloadsService) {}

  @Post('video')
  @ApiOperation({
    summary:
      'Authorize and request video download with TikTok-style publisher watermark',
    description:
      'Validates user authorization against publisher settings and RBAC. Generates signed download URL and logs audit record with publisher attribution.',
  })
  @ApiResponse({ status: 201, type: DownloadTokenResponseDto })
  async requestVideoDownload(
    @CurrentUser('sub') userId: string,
    @Body() dto: RequestVideoDownloadDto,
    @Req() req: Request,
  ): Promise<DownloadTokenResponseDto> {
    return this.service.authorizeVideoDownload(
      userId,
      dto,
      req.ip,
      req.headers['user-agent'],
    );
  }

  @Post('post')
  @ApiOperation({
    summary:
      'Authorize and request social post media download with publisher watermark',
    description:
      'Validates post publisher permission and group membership. Generates watermarked download response with publisher identity.',
  })
  @ApiResponse({ status: 201, type: DownloadTokenResponseDto })
  async requestPostDownload(
    @CurrentUser('sub') userId: string,
    @Body() dto: RequestPostDownloadDto,
    @Req() req: Request,
  ): Promise<DownloadTokenResponseDto> {
    return this.service.authorizePostDownload(
      userId,
      dto,
      req.ip,
      req.headers['user-agent'],
    );
  }

  @Post('file')
  @ApiOperation({
    summary: 'Authorize generic media/file download (Images, Audio, Documents)',
    description:
      'Validates group membership authorization and produces signed download URL.',
  })
  async requestFileDownload(
    @CurrentUser('sub') userId: string,
    @Body() dto: RequestFileDownloadDto,
    @Req() req: Request,
  ): Promise<DownloadTokenResponseDto> {
    return this.service.authorizeFileDownload(
      userId,
      dto,
      req.ip,
      req.headers['user-agent'],
    );
  }

  @Get('check-permission')
  @ApiOperation({
    summary: 'Check if user has permission to download video, post, or media',
  })
  @ApiQuery({ name: 'type', enum: ['video', 'post', 'file'] })
  @ApiQuery({ name: 'id', description: 'Content ID' })
  async checkPermission(
    @CurrentUser('sub') userId: string,
    @Query('type') type: 'video' | 'post' | 'file',
    @Query('id') id: string,
  ) {
    return this.service.checkDownloadPermission(userId, type, id);
  }

  @Get('history')
  @ApiOperation({ summary: 'Get current user download history & analytics' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getMyDownloadHistory(
    @CurrentUser('sub') userId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.service.getUserHistory(userId, +page, +limit);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get overall download statistics (User or Global)' })
  async getDownloadStats(@CurrentUser('sub') userId: string) {
    return this.service.getDownloadStats(userId);
  }

  @Get('file/:downloadId')
  @ApiOperation({
    summary: 'Stream / Download media file via authorization record ID',
  })
  @ApiParam({
    name: 'downloadId',
    description: 'Download Authorization Record ID',
  })
  async streamDownload(
    @Param('downloadId') downloadId: string,
    @CurrentUser('sub') userId: string,
    @Res() res: Response,
  ) {
    const info = await this.service.getDownloadStreamInfo(downloadId, userId);

    if (info.remoteUrl) {
      return res.redirect(info.remoteUrl);
    }

    if (!info.filePath || !fs.existsSync(info.filePath)) {
      throw new NotFoundException(
        'Requested file was not found on storage server',
      );
    }

    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${info.filename}"`,
    );
    res.setHeader('Content-Type', info.mimeType);

    const stream = fs.createReadStream(info.filePath);
    stream.pipe(res);
  }
}
