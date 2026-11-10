// src/modules/video-comments/video-comments.service.ts
import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { VideoCommentsRepository } from './video-comments.repository.js';
import { CreateVideoCommentDto } from './dto/create-video-comment.dto.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import { AppRole } from '../../common/constants/roles.js';
import { MentionsService } from '../mentions/mentions.service.js';
import { NotificationsService } from '../notifications/notifications.service.js';
import { NotificationType } from '@prisma/client';

@Injectable()
export class VideoCommentsService {
  constructor(
    private readonly repo: VideoCommentsRepository,
    private readonly prisma: PrismaService,
    private readonly mentionsService: MentionsService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async create(videoId: string, userId: string, dto: CreateVideoCommentDto) {
    const video = await this.prisma.video.findUnique({
      where: { id: videoId },
    });
    if (!video) throw new NotFoundException('Video not found');

    const sanitized =
      this.mentionsService.sanitizePlainText(dto.content) ?? dto.content;
    const created = await this.repo.create(
      videoId,
      userId,
      sanitized,
      dto.parentId,
    );

    if (video.visibility !== 'PRIVATE') {
      const mentionedIds =
        await this.mentionsService.extractAndValidateAtMentionUserIds(
          sanitized,
          [],
          userId,
        );
      if (mentionedIds.length > 0) {
        const preview = this.mentionsService.stripTokensToReadableText(sanitized);
        for (const mentionedId of mentionedIds) {
          if (mentionedId === userId) continue;
          this.notificationsService
            .create({
              userId: mentionedId,
              type: NotificationType.MENTION,
              title: 'You were mentioned on a video',
              body: preview ? preview.slice(0, 120) : 'Someone mentioned you in a video comment',
              data: { videoId, commentId: created.id },
            })
            .catch(() => null);
        }
      }
    }

    return created;
  }

  async findByVideo(videoId: string, page = 1, limit = 20) {
    return this.repo.findByVideo(videoId, page, limit);
  }

  async update(commentId: string, userId: string, content: string) {
    const comment = await this.repo.findById(commentId);
    if (!comment) throw new NotFoundException('Comment not found');

    if (comment.userId !== userId) {
      throw new ForbiddenException('You can only edit your own comment');
    }

    return this.repo.update(commentId, content);
  }

  async delete(commentId: string, userId: string) {
    const comment = await this.repo.findById(commentId);
    if (!comment) throw new NotFoundException('Comment not found');

    if (comment.userId !== userId) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        include: { role: true },
      });
      if (
        user?.role.name !== AppRole.SUPER_ADMIN &&
        user?.role.name !== AppRole.ADMIN
      ) {
        throw new ForbiddenException(
          'Insufficient permissions to delete this comment',
        );
      }
    }

    await this.repo.softDelete(commentId);
    return { message: 'Comment deleted' };
  }

  async toggleLike(commentId: string, userId: string) {
    const comment = await this.repo.findById(commentId);
    if (!comment) throw new NotFoundException('Comment not found');
    return this.repo.toggleLike(commentId, userId);
  }

  async togglePin(commentId: string, userId: string) {
    const comment = await this.repo.findById(commentId);
    if (!comment) throw new NotFoundException('Comment not found');

    // Video uploader or admin can pin
    const video = await this.prisma.video.findUnique({
      where: { id: comment.videoId },
    });
    if (video?.uploadedById !== userId) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        include: { role: true },
      });
      if (
        user?.role.name !== AppRole.SUPER_ADMIN &&
        user?.role.name !== AppRole.ADMIN
      ) {
        throw new ForbiddenException('Only video uploader can pin comments');
      }
    }

    return this.repo.pinComment(commentId, !comment.isPinned);
  }
}
