// src/modules/admin/services/admin-storage.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';

@Injectable()
export class AdminStorageService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
  ) {}

  async getStorageStats() {
    const [totalFiles, typeGroups, providerGroups] = await Promise.all([
      this.prisma.file.count(),
      this.prisma.file.groupBy({
        by: ['fileType'],
        _count: { id: true },
        _sum: { size: true },
      }),
      this.prisma.file.groupBy({
        by: ['provider'],
        _count: { id: true },
        _sum: { size: true },
      }),
    ]);

    let totalSizeBytes = 0;
    const byType = typeGroups.map((g) => {
      const sizeBytes = Number(g._sum.size ?? 0);
      totalSizeBytes += sizeBytes;
      return {
        type: g.fileType,
        count: g._count.id,
        sizeBytes,
      };
    });

    const byProvider = providerGroups.map((g) => ({
      provider: g.provider,
      count: g._count.id,
      sizeBytes: Number(g._sum.size ?? 0),
    }));

    return {
      totalFiles,
      totalSizeBytes,
      byType,
      byProvider,
    };
  }

  async listFiles(query: {
    page?: number;
    limit?: number;
    search?: string;
    fileType?: string;
    provider?: string;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.search) {
      where.OR = [
        { originalName: { contains: query.search, mode: 'insensitive' } },
        { fileName: { contains: query.search, mode: 'insensitive' } },
      ];
    }
    if (query.fileType && query.fileType !== 'ALL') {
      where.fileType = query.fileType;
    }
    if (query.provider && query.provider !== 'ALL') {
      where.provider = query.provider;
    }

    const [files, total] = await Promise.all([
      this.prisma.file.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.file.count({ where }),
    ]);

    const items = files.map((f) => ({
      ...f,
      size: Number(f.size),
    }));

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
    };
  }

  async deleteFile(id: string, actorId: string, reason?: string) {
    const file = await this.prisma.file.findUnique({ where: { id } });
    if (!file) {
      throw new NotFoundException(`File ${id} not found`);
    }

    await this.prisma.file.delete({ where: { id } });

    await this.auditService.log({
      actorId,
      action: 'STORAGE_FILE_DELETED',
      targetType: 'FILE',
      targetId: id,
      before: {
        originalName: file.originalName,
        storageKey: file.storageKey,
        size: Number(file.size),
      },
      reason,
    });

    return { success: true, message: 'File deleted successfully' };
  }
}
