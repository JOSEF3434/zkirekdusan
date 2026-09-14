// src/modules/admin/services/admin-dashboard.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';

@Injectable()
export class AdminDashboardService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AdminAuditService,
  ) {}

  async getMetrics() {
    const [
      totalUsers,
      activeUsers,
      bannedUsers,
      totalGroups,
      pendingGroups,
      activeGroups,
      totalChannels,
      totalVideos,
      totalPosts,
      pendingReports,
      totalReports,
      totalStreams,
      activeStreams,
      storageStats,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { status: 'ACTIVE' } }),
      this.prisma.user.count({ where: { status: 'BANNED' } }),
      this.prisma.group.count(),
      this.prisma.group.count({ where: { status: 'PENDING_APPROVAL' } }),
      this.prisma.group.count({ where: { status: 'ACTIVE' } }),
      this.prisma.videoChannel.count({ where: { status: 'ACTIVE' } }),
      this.prisma.video.count({ where: { status: { not: 'DELETED' } } }),
      this.prisma.post.count({ where: { deletedAt: null } }),
      this.prisma.report.count({ where: { status: 'PENDING' } }),
      this.prisma.report.count(),
      this.prisma.liveStream.count(),
      this.prisma.liveStream.count({ where: { status: 'LIVE' } }),
      this.prisma.file.aggregate({
        _sum: { size: true },
        _count: { id: true },
      }),
    ]);

    return {
      users: {
        total: totalUsers,
        active: activeUsers,
        banned: bannedUsers,
        inactive: totalUsers - activeUsers - bannedUsers,
      },
      groups: { total: totalGroups, pending: pendingGroups, active: activeGroups },
      channels: { total: totalChannels },
      content: { total: totalVideos + totalPosts, videos: totalVideos, posts: totalPosts },
      reports: { total: totalReports, pending: pendingReports },
      live: { total: totalStreams, activeStreams },
      storage: {
        totalFiles: storageStats._count.id,
        totalBytes: Number(storageStats._sum.size ?? 0),
      },
      recentActivity: await this.prisma.auditLog.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: {
              id: true,
              username: true,
              profile: { select: { displayName: true } },
            },
          },
        },
      }),
    };
  }

  async getPlatformMetrics() {
    return this.getMetrics();
  }
}
