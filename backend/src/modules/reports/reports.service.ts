import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateReportDto } from './dto/create-report.dto.js';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async createReport(reporterId: string, dto: CreateReportDto) {
    if (dto.targetType === 'USER' && dto.targetId === reporterId) {
      throw new BadRequestException('You cannot report yourself');
    }

    // Determine targetUserId if not explicitly passed
    let targetUserId = dto.targetUserId;
    if (!targetUserId && dto.targetType === 'USER') {
      targetUserId = dto.targetId;
    }

    const report = await this.prisma.report.create({
      data: {
        reporterId,
        targetType: dto.targetType as any,
        targetId: dto.targetId,
        targetUserId,
        reason: dto.reason as any,
        comment: dto.comment,
        status: 'PENDING',
      },
    });

    return {
      success: true,
      message: 'Report submitted successfully. Our team will review it.',
      reportId: report.id,
    };
  }

  async getMyReports(userId: string) {
    return this.prisma.report.findMany({
      where: { reporterId: userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        targetType: true,
        targetId: true,
        reason: true,
        comment: true,
        status: true,
        createdAt: true,
      },
    });
  }
}
