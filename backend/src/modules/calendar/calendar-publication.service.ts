// src/modules/calendar/calendar-publication.service.ts
import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  OnModuleDestroy,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { NotificationsService } from '../notifications/notifications.service.js';
import {
  NotificationType,
  PostType,
  PostVisibility,
  CalendarReminderRepeat,
  CalendarPublicationStatus,
} from '@prisma/client';
import {
  getEthiopianDate,
  formatEthiopianDate,
  ethiopianToGregorian,
  EthiopianDate,
  getDaysInEthiopianMonth,
} from './calendar-ethiopian.util.js';
import { ConfigService } from '@nestjs/config';
import { Redis } from 'ioredis';

@Injectable()
export class CalendarPublicationService implements OnModuleDestroy {
  private readonly logger = new Logger(CalendarPublicationService.name);
  private redisClient: Redis | null = null;
  private readonly inMemoryLocks = new Set<string>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly configService: ConfigService,
  ) {
    this.initRedis();
  }

  onModuleDestroy() {
    if (this.redisClient) {
      try {
        this.redisClient.disconnect();
      } catch {}
      this.redisClient = null;
    }
  }

  private initRedis() {
    try {
      const host = this.configService.get<string>('REDIS_HOST') || 'localhost';
      const port = this.configService.get<number>('REDIS_PORT') || 6379;
      this.redisClient = new Redis({
        host,
        port,
        maxRetriesPerRequest: null,
        enableOfflineQueue: false,
        lazyConnect: true,
      });
      this.redisClient.on('error', () => {
        // Fall back gracefully to in-memory locking without unhandled exception
      });
    } catch {
      this.redisClient = null;
    }
  }

  /**
   * Acquire a distributed lock with TTL in milliseconds.
   */
  private async acquireLock(key: string, ttlMs = 60000): Promise<boolean> {
    if (this.redisClient && this.redisClient.status === 'ready') {
      try {
        const acquired = await this.redisClient.set(key, '1', 'PX', ttlMs, 'NX');
        return acquired === 'OK';
      } catch {
        // Fallback to in-memory
      }
    }

    if (this.inMemoryLocks.has(key)) {
      return false;
    }
    this.inMemoryLocks.add(key);
    setTimeout(() => this.inMemoryLocks.delete(key), ttlMs);
    return true;
  }

  /**
   * Release a distributed lock.
   */
  private async releaseLock(key: string): Promise<void> {
    if (this.redisClient && this.redisClient.status === 'ready') {
      try {
        await this.redisClient.del(key);
      } catch {
        // Fallback
      }
    }
    this.inMemoryLocks.delete(key);
  }

  /**
   * Publish all due monthly feasts for the given reference date (default: now).
   * Scheduled at 12:00 PM Africa/Addis_Ababa.
   */
  async publishDueMonthlyFeasts(overrideDate?: Date) {
    const currentEth = getEthiopianDate(overrideDate ?? new Date());
    this.logger.log(
      `[CalendarPublication] Checking monthly feasts for Ethiopian date: ${formatEthiopianDate(
        currentEth.year,
        currentEth.month,
        currentEth.day,
      )}`,
    );

    const eligibleNotes = await this.prisma.calendarNote.findMany({
      where: {
        deletedAt: null,
        isAutoPublishEnabled: true,
        OR: [
          { recurrenceType: CalendarReminderRepeat.MONTHLY },
          { reminderRepeat: CalendarReminderRepeat.MONTHLY },
        ],
        AND: [
          {
            OR: [
              { ethiopianDay: currentEth.day },
              { reminderEthiopianDay: currentEth.day },
            ],
          },
        ],
      },
      include: {
        media: {
          include: { file: true },
          orderBy: { order: 'asc' },
        },
      },
    });

    this.logger.log(
      `[CalendarPublication] Found ${eligibleNotes.length} eligible monthly notes for day ${currentEth.day}`,
    );

    const results: any[] = [];
    for (const note of eligibleNotes) {
      const scheduledAt = ethiopianToGregorian(
        currentEth.year,
        currentEth.month,
        currentEth.day,
        12,
        0,
      );
      const res = await this.processPublication(
        note,
        CalendarReminderRepeat.MONTHLY,
        currentEth,
        scheduledAt,
      );
      results.push(res);
    }
    return results;
  }

  /**
   * Publish all due annual feasts for the given reference date (default: now).
   * Scheduled at 12:10 PM Africa/Addis_Ababa.
   */
  async publishDueAnnualFeasts(overrideDate?: Date) {
    const currentEth = getEthiopianDate(overrideDate ?? new Date());
    this.logger.log(
      `[CalendarPublication] Checking annual feasts for Ethiopian date: ${formatEthiopianDate(
        currentEth.year,
        currentEth.month,
        currentEth.day,
      )}`,
    );

    // Month matching notes
    const eligibleNotes = await this.prisma.calendarNote.findMany({
      where: {
        deletedAt: null,
        isAutoPublishEnabled: true,
        OR: [
          { recurrenceType: CalendarReminderRepeat.YEARLY },
          { reminderRepeat: CalendarReminderRepeat.YEARLY },
        ],
        AND: [
          {
            OR: [
              { ethiopianMonth: currentEth.month },
              { reminderEthiopianMonth: currentEth.month },
            ],
          },
        ],
      },
      include: {
        media: {
          include: { file: true },
          orderBy: { order: 'asc' },
        },
      },
    });

    const matchingNotes = eligibleNotes.filter((note) => {
      const targetDay = note.reminderEthiopianDay ?? note.ethiopianDay;
      const maxDays = getDaysInEthiopianMonth(currentEth.year, currentEth.month);
      const effectiveDay = Math.min(targetDay, maxDays);
      return effectiveDay === currentEth.day;
    });

    this.logger.log(
      `[CalendarPublication] Found ${matchingNotes.length} eligible annual notes for ${currentEth.month}/${currentEth.day}`,
    );

    const results: any[] = [];
    for (const note of matchingNotes) {
      const scheduledAt = ethiopianToGregorian(
        currentEth.year,
        currentEth.month,
        currentEth.day,
        12,
        10,
      );
      const res = await this.processPublication(
        note,
        CalendarReminderRepeat.YEARLY,
        currentEth,
        scheduledAt,
      );
      results.push(res);
    }
    return results;
  }

  /**
   * Process a single feast publication with idempotency, distributed locking,
   * database transaction, post generation, and notification broadcast.
   */
  async processPublication(
    note: any,
    recurrenceType: CalendarReminderRepeat,
    occurrenceEth: EthiopianDate,
    scheduledAt: Date,
  ) {
    const occurrenceDateStr = formatEthiopianDate(
      occurrenceEth.year,
      occurrenceEth.month,
      occurrenceEth.day,
    );
    const lockKey = `lock:calendar:publish:${note.id}:${recurrenceType}:${occurrenceDateStr}`;

    const acquired = await this.acquireLock(lockKey);
    if (!acquired) {
      this.logger.warn(
        `[CalendarPublication] Concurrency lock already held for ${lockKey}. Skipping concurrent execution.`,
      );
      return { skipped: true, reason: 'LOCKED' };
    }

    try {
      // 1. Check existing occurrence
      let occurrence = await this.prisma.calendarPublicationOccurrence.findUnique({
        where: {
          calendar_note_recurrence_occurrence_unique: {
            calendarNoteId: note.id,
            recurrenceType,
            occurrenceEthiopianDate: occurrenceDateStr,
          },
        },
      });

      if (occurrence) {
        if (occurrence.publicationStatus === CalendarPublicationStatus.PUBLISHED) {
          this.logger.log(
            `[CalendarPublication] Note ${note.id} already published for ${occurrenceDateStr}. Skipping.`,
          );
          return { skipped: true, occurrence };
        }
        if (occurrence.publicationStatus === CalendarPublicationStatus.CANCELLED) {
          this.logger.log(
            `[CalendarPublication] Occurrence ${occurrence.id} was cancelled by administrator. Skipping.`,
          );
          return { skipped: true, occurrence };
        }
      } else {
        // Record pending occurrence
        occurrence = await this.prisma.calendarPublicationOccurrence.create({
          data: {
            calendarNoteId: note.id,
            recurrenceType,
            occurrenceEthiopianDate: occurrenceDateStr,
            occurrenceYear: occurrenceEth.year,
            occurrenceMonth: occurrenceEth.month,
            occurrenceDay: occurrenceEth.day,
            scheduledAt,
            publicationStatus: CalendarPublicationStatus.PENDING,
          },
        });
      }

      // 2. Perform publication within database transaction
      const result = await this.prisma.$transaction(async (tx) => {
        // Determine post content and type
        const mediaItems = note.media ?? [];
        let postType: PostType = PostType.TEXT;
        if (mediaItems.length === 1) {
          postType = PostType.IMAGE;
        } else if (mediaItems.length > 1) {
          postType = PostType.CAROUSEL;
        }

        const fullContent = [
          note.title?.trim(),
          note.content?.trim(),
        ]
          .filter(Boolean)
          .join('\n\n');

        // Create the post
        const post = await tx.post.create({
          data: {
            authorId: note.userId,
            type: postType,
            visibility: PostVisibility.PUBLIC,
            content: fullContent.length > 0 ? fullContent : 'የእለቱ ዝክረ ቅዱሳን በዓል',
            hashtags: ['ዝክረቅዱሳን', 'የኢትዮጵያኦርቶዶክስ', 'በዓላት'],
            mentions: [],
            allowDownloads: note.allowDownload ?? false,
            downloadPermission: 'PUBLIC',
            publishedAt: new Date(),
            calendarNoteId: note.id,
          },
        });

        // Attach media files to post
        if (mediaItems.length > 0) {
          await tx.postMedia.createMany({
            data: mediaItems.map((m: any, index: number) => ({
              postId: post.id,
              fileId: m.fileId,
              order: m.order ?? index,
              caption: m.caption,
            })),
          });
        }

        // Mark occurrence as PUBLISHED
        const updatedOccurrence = await tx.calendarPublicationOccurrence.update({
          where: { id: occurrence.id },
          data: {
            publicationStatus: CalendarPublicationStatus.PUBLISHED,
            publishedAt: new Date(),
            generatedPostId: post.id,
            lastError: null,
          },
        });

        return { post, updatedOccurrence };
      });

      // 3. Send Notification to all eligible users
      // Requirement 4 & 7: Title must be exactly: የእለቱ ወርሃዊ በዐላት (monthly)
      // Requirement 5 & 7: Title must be exactly: የእለቱ አመታዊ በአላት (annual)
      const notificationTitle =
        recurrenceType === CalendarReminderRepeat.MONTHLY
          ? 'የእለቱ ወርሃዊ በዐላት'
          : 'የእለቱ አመታዊ በአላት';

      const previewBody =
        note.title?.trim() ||
        (note.content && note.content.length > 120
          ? `${note.content.substring(0, 117)}...`
          : note.content) ||
        `የዕለት ${occurrenceEth.day}/${occurrenceEth.month}/${occurrenceEth.year} በዓል`;

      await this.notificationsService
        .notifyAllUsers({
          title: notificationTitle,
          body: previewBody,
          type: NotificationType.SYSTEM,
          data: {
            noteId: note.id,
            calendarNoteId: note.id,
            postId: result.post.id,
            type: 'CALENDAR_NOTE',
            action: 'CALENDAR_FEAST_PUBLISHED',
            recurrenceType,
            occurrenceDate: occurrenceDateStr,
            localized: {
              am: { title: notificationTitle, body: previewBody },
              en: {
                title:
                  recurrenceType === CalendarReminderRepeat.MONTHLY
                    ? "Today's Monthly Feast"
                    : "Today's Annual Feast",
                body: previewBody,
              },
            },
          },
        })
        .catch((err) => {
          this.logger.error(
            `[CalendarPublication] Notification broadcast error for note ${note.id}`,
            err,
          );
        });

      this.logger.log(
        `[CalendarPublication] ✅ Successfully published ${recurrenceType} feast for note ${note.id} (Post ID: ${result.post.id})`,
      );

      return {
        success: true,
        occurrence: result.updatedOccurrence,
        postId: result.post.id,
      };
    } catch (err: any) {
      this.logger.error(
        `[CalendarPublication] ❌ Failed to publish feast for note ${note.id}: ${err.message}`,
        err.stack,
      );

      // Record error on occurrence
      await this.prisma.calendarPublicationOccurrence
        .upsert({
          where: {
            calendar_note_recurrence_occurrence_unique: {
              calendarNoteId: note.id,
              recurrenceType,
              occurrenceEthiopianDate: occurrenceDateStr,
            },
          },
          update: {
            publicationStatus: CalendarPublicationStatus.FAILED,
            retryCount: { increment: 1 },
            lastError: err.message ?? 'Unknown error during publication',
          },
          create: {
            calendarNoteId: note.id,
            recurrenceType,
            occurrenceEthiopianDate: occurrenceDateStr,
            occurrenceYear: occurrenceEth.year,
            occurrenceMonth: occurrenceEth.month,
            occurrenceDay: occurrenceEth.day,
            scheduledAt,
            publicationStatus: CalendarPublicationStatus.FAILED,
            retryCount: 1,
            lastError: err.message ?? 'Unknown error during publication',
          },
        })
        .catch(() => null);

      return { success: false, error: err.message };
    } finally {
      await this.releaseLock(lockKey);
    }
  }

  // ─── ADMIN MANAGEMENT METHODS ──────────────────────────────────────────────

  /**
   * Retrieves upcoming publication occurrences.
   */
  async getUpcomingOccurrences(limit = 20) {
    return this.prisma.calendarPublicationOccurrence.findMany({
      where: {
        publicationStatus: {
          in: [CalendarPublicationStatus.PENDING, CalendarPublicationStatus.SCHEDULED],
        },
      },
      include: {
        calendarNote: {
          select: {
            id: true,
            title: true,
            content: true,
            ethiopianYear: true,
            ethiopianMonth: true,
            ethiopianDay: true,
          },
        },
      },
      orderBy: { scheduledAt: 'asc' },
      take: limit,
    });
  }

  /**
   * Retrieves publication history.
   */
  async getPublicationHistory(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [total, items] = await Promise.all([
      this.prisma.calendarPublicationOccurrence.count(),
      this.prisma.calendarPublicationOccurrence.findMany({
        skip,
        take: limit,
        include: {
          calendarNote: {
            select: {
              id: true,
              title: true,
              ethiopianYear: true,
              ethiopianMonth: true,
              ethiopianDay: true,
            },
          },
          generatedPost: {
            select: {
              id: true,
              publishedAt: true,
            },
          },
        },
        orderBy: { updatedAt: 'desc' },
      }),
    ]);

    return {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      items,
    };
  }

  /**
   * Allows an administrator to cancel a scheduled occurrence before publication.
   */
  async cancelOccurrence(occurrenceId: string) {
    const occurrence = await this.prisma.calendarPublicationOccurrence.findUnique({
      where: { id: occurrenceId },
    });

    if (!occurrence) {
      throw new NotFoundException('Publication occurrence not found');
    }

    if (occurrence.publicationStatus === CalendarPublicationStatus.PUBLISHED) {
      throw new BadRequestException('Cannot cancel an already published feast occurrence');
    }

    return this.prisma.calendarPublicationOccurrence.update({
      where: { id: occurrenceId },
      data: {
        publicationStatus: CalendarPublicationStatus.CANCELLED,
      },
    });
  }

  /**
   * Retries a failed occurrence manually.
   */
  async retryOccurrence(occurrenceId: string) {
    const occurrence = await this.prisma.calendarPublicationOccurrence.findUnique({
      where: { id: occurrenceId },
      include: {
        calendarNote: {
          include: {
            media: {
              include: { file: true },
              orderBy: { order: 'asc' },
            },
          },
        },
      },
    });

    if (!occurrence) {
      throw new NotFoundException('Publication occurrence not found');
    }

    if (occurrence.publicationStatus === CalendarPublicationStatus.PUBLISHED) {
      return { message: 'Already published', occurrence };
    }

    const ethDate: EthiopianDate = {
      year: occurrence.occurrenceYear,
      month: occurrence.occurrenceMonth,
      day: occurrence.occurrenceDay,
    };

    return this.processPublication(
      occurrence.calendarNote,
      occurrence.recurrenceType,
      ethDate,
      occurrence.scheduledAt,
    );
  }

  /**
   * Update recurrence and publication settings for a note (SUPER_ADMIN only).
   */
  async updatePublicationSettings(
    noteId: string,
    recurrenceType: CalendarReminderRepeat,
    isAutoPublishEnabled: boolean,
    autoPublishTime = '12:00',
  ) {
    const note = await this.prisma.calendarNote.findUnique({
      where: { id: noteId },
    });

    if (!note) {
      throw new NotFoundException('Calendar note not found');
    }

    return this.prisma.calendarNote.update({
      where: { id: noteId },
      data: {
        recurrenceType,
        reminderRepeat: recurrenceType, // Keep synced with reminderRepeat
        isAutoPublishEnabled,
        autoPublishTime,
      },
      include: {
        media: {
          include: { file: true },
          orderBy: { order: 'asc' },
        },
      },
    });
  }
}
