// src/modules/uploads/group-uploads.controller.ts
import 'multer';
import {
  Controller,
  DefaultValuePipe,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
  UploadedFile,
  UseGuards,
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
  ApiQuery,
  ApiBody,
} from '@nestjs/swagger';
import { UploadsService } from './uploads.service.js';
import { FileResponseDto } from './dto/file-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { GroupMembershipGuard } from '../../common/guards/group-membership.guard.js';

@ApiTags('Group Uploads')
@ApiBearerAuth()
@Controller('groups/:groupId/files')
@UseGuards(GroupMembershipGuard)
@Throttle({ default: { limit: 20, ttl: 60000 } })
export class GroupUploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  @Post()
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload a file to a group (Group members only)' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
      },
    },
  })
  @ApiResponse({ status: 201, type: FileResponseDto })
  async uploadFile(
    @Param('groupId') groupId: string,
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<FileResponseDto> {
    return this.uploadsService.uploadGroupFile(groupId, userId, file);
  }

  @Get()
  @ApiOperation({ summary: 'List files uploaded to a group' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async listGroupFiles(
    @Param('groupId') groupId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.uploadsService.listGroupFiles(groupId, page, limit);
  }

  @Delete(':fileId')
  @ApiOperation({
    summary: 'Delete a file uploaded to a group (Uploader only)',
  })
  async deleteFile(
    @Param('fileId') fileId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.uploadsService.deleteFile(fileId, userId);
  }
}
