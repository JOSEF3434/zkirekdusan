// src/modules/uploads/uploads.service.ts
import 'multer';
import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import crypto from 'crypto';
import path from 'path';
import { FileProvider, FileType } from '@prisma/client';
import { UploadsRepository } from './uploads.repository.js';
import { IStorageProvider } from './providers/storage.interface.js';
import { STORAGE_PROVIDER_TOKEN } from './providers/storage.factory.js';
import { FileResponseDto } from './dto/file-response.dto.js';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class UploadsService {
  constructor(
    private readonly uploadsRepository: UploadsRepository,
    @Inject(STORAGE_PROVIDER_TOKEN)
    private readonly storageProvider: IStorageProvider & Record<string, any>,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * Group-scoped file upload endpoint requirement:
   * Validates group status, user membership, MIME type, file size,
   * uploads to configured storage (Local or Cloudinary fallback),
   * and saves database record.
   */
  async uploadGroupFile(
    groupId: string,
    uploaderId: string,
    file: Express.Multer.File,
  ): Promise<FileResponseDto> {
    if (!file) {
      throw new BadRequestException('File is required');
    }

    // 1. Verify Group exists and is ACTIVE
    const group = await this.prisma.group.findUnique({
      where: { id: groupId, deletedAt: null },
      select: { id: true, status: true },
    });

    if (!group) {
      throw new NotFoundException('Group not found');
    }

    if (group.status !== 'ACTIVE') {
      throw new ForbiddenException(
        'This group is pending approval or inactive — uploads are disabled until approved by an Admin',
      );
    }

    // 2. Determine file category (IMAGE, VIDEO, AUDIO, DOCUMENT, etc.)
    const fileType = this.resolveFileType(file.mimetype);

    // 3. Compute SHA-256 checksum
    const checksum = crypto
      .createHash('sha256')
      .update(file.buffer)
      .digest('hex');

    // 4. Upload via storage provider
    const subfolder = `groups/${groupId}/${fileType.toLowerCase()}`;
    const result = await this.storageProvider.upload(file, subfolder);

    const ext = path.extname(file.originalname).toLowerCase().replace('.', '');

    // 5. Persist file metadata
    const dbFile = await this.uploadsRepository.createFile({
      originalName: file.originalname,
      fileName: path.basename(result.storageKey),
      mimeType: file.mimetype,
      extension: ext,
      size: file.size,
      fileType,
      provider: result.provider,
      storageKey: result.storageKey,
      url: result.url,
      uploadedById: uploaderId,
      groupId,
      checksum,
    });

    return {
      id: dbFile.id,
      originalName: dbFile.originalName,
      mimeType: dbFile.mimeType,
      size: Number(dbFile.size),
      fileType: dbFile.fileType,
      provider: dbFile.provider,
      url: dbFile.url,
      status: dbFile.status,
      uploadedById: dbFile.uploadedById,
      groupId: dbFile.groupId,
      createdAt: dbFile.createdAt,
    };
  }

  async listGroupFiles(groupId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.uploadsRepository.findByGroup(
      groupId,
      skip,
      limit,
    );

    const data: FileResponseDto[] = items.map((f) => ({
      id: f.id,
      originalName: f.originalName,
      mimeType: f.mimeType,
      size: Number(f.size),
      fileType: f.fileType,
      provider: f.provider,
      url: f.url,
      status: f.status,
      uploadedById: f.uploadedById,
      groupId: f.groupId,
      createdAt: f.createdAt,
    }));

    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      },
    };
  }

  async deleteFile(fileId: string, userId: string) {
    const file = await this.uploadsRepository.findById(fileId);
    if (!file) {
      throw new NotFoundException('File not found');
    }

    if (file.uploadedById !== userId) {
      throw new ForbiddenException('You can only delete files you uploaded');
    }

    await this.storageProvider.delete(file.storageKey);
    await this.uploadsRepository.softDelete(fileId);

    return { message: 'File deleted successfully' };
  }

  private resolveFileType(mimeType: string): FileType {
    if (mimeType.startsWith('image/')) return FileType.IMAGE;
    if (mimeType.startsWith('video/')) return FileType.VIDEO;
    if (mimeType.startsWith('audio/')) return FileType.AUDIO;
    if (
      mimeType.includes('pdf') ||
      mimeType.includes('msword') ||
      mimeType.includes('document')
    ) {
      return FileType.DOCUMENT;
    }
    if (
      mimeType.includes('zip') ||
      mimeType.includes('tar') ||
      mimeType.includes('gzip')
    ) {
      return FileType.ARCHIVE;
    }
    return FileType.OTHER;
  }
}
