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
      'Authorize and request video download (Quality selection: 240p to 4K)',
    description:
      'Validates user authorization against Global & Group RBAC. Generates signed download URL and logs audit record.',
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
  ) {
    return this.service.authorizeFileDownload(
      userId,
      dto,
      req.ip,
      req.headers['user-agent'],
    );
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
