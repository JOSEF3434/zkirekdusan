// src/modules/uploads/uploads.controller.ts
import 'multer';
import {
  Body,
  Controller,
  Delete,
  Param,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { UploadsService } from './uploads.service.js';
import { FileResponseDto } from './dto/file-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Uploads')
@ApiBearerAuth()
@Controller('uploads')
@Throttle({ default: { limit: 30, ttl: 60000 } })
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  @Post('chat')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Upload chat media attachment (image, video, audio, document)',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
        conversationId: { type: 'string' },
      },
    },
  })
  @ApiResponse({ status: 201, type: FileResponseDto })
  async uploadChatMedia(
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body('conversationId') conversationId?: string,
  ): Promise<FileResponseDto> {
    return this.uploadsService.uploadChatMedia(userId, file, conversationId);
  }

  @Post('media')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'General media upload' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
      },
    },
  })
  @ApiResponse({ status: 201, type: FileResponseDto })
  async uploadGeneralMedia(
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<FileResponseDto> {
    return this.uploadsService.uploadPostMedia(userId, file);
  }

  @Delete(':fileId')
  @ApiOperation({ summary: 'Delete an uploaded file' })
  async deleteFile(
    @Param('fileId') fileId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.uploadsService.deleteFile(fileId, userId);
  }
}
