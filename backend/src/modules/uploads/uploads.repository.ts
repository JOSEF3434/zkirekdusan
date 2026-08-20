// src/modules/uploads/uploads.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { FileProvider, FileStatus, FileType } from '@prisma/client';

@Injectable()
export class UploadsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createFile(data: {
    originalName: string;
    fileName: string;
    mimeType: string;
    extension: string;
    size: number;
    fileType: FileType;
    provider: FileProvider;
    storageKey: string;
    url: string;
    uploadedById: string;
    groupId?: string | null;
    checksum?: string;
  }) {
    return this.prisma.file.create({
      data: {
        originalName: data.originalName,
        fileName: data.fileName,
        mimeType: data.mimeType,
        extension: data.extension,
        size: BigInt(data.size),
        fileType: data.fileType,
        provider: data.provider,
        storageKey: data.storageKey,
        url: data.url,
        status: FileStatus.READY,
        uploadedById: data.uploadedById,
        groupId: data.groupId ?? null,
        checksum: data.checksum,
      },
    });
  }

  async findById(id: string) {
    return this.prisma.file.findFirst({
      where: { id, deletedAt: null },
    });
  }

  async findByGroup(groupId: string, skip = 0, take = 20) {
    const where = { groupId, deletedAt: null };
    const [items, total] = await Promise.all([
      this.prisma.file.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.file.count({ where }),
    ]);

    return { items, total };
  }

  async softDelete(id: string) {
    return this.prisma.file.update({
      where: { id },
      data: { deletedAt: new Date(), status: FileStatus.DELETED },
    });
  }
}
