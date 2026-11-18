import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateCalendarNoteDto } from './dto/create-calendar-note.dto.js';
import { UpdateCalendarNoteDto } from './dto/update-calendar-note.dto.js';
import { QueryCalendarNotesDto } from './dto/query-calendar-notes.dto.js';
import { NotificationsService } from '../notifications/notifications.service.js';
import {
  calculateRollingOneYearWindow,
  getEthiopianDate,
  formatEthiopianDate,
  parseEthiopianDate,
} from './calendar-ethiopian.util.js';

function validateReminderRule(
  dto: CreateCalendarNoteDto | UpdateCalendarNoteDto,
) {
  const repeat = dto.reminderRepeat;
  if (repeat === undefined || repeat === 'NONE') return;
  if (dto.reminderHour === undefined || dto.reminderMinute === undefined) {
    throw new ForbiddenException('Reminder hour and minute are required');
  }
  if (repeat === 'MONTHLY' && dto.reminderEthiopianDay === undefined) {
    throw new ForbiddenException('Monthly reminders require an Ethiopian day');
  }
  if (
    repeat === 'YEARLY' &&
    (dto.reminderEthiopianMonth === undefined ||
      dto.reminderEthiopianDay === undefined)
  ) {
    throw new ForbiddenException(
      'Yearly reminders require an Ethiopian month and day',
    );
  }
}

@Injectable()
export class CalendarService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async create(userId: string, dto: CreateCalendarNoteDto) {
    validateReminderRule(dto);

    // Idempotency: if client supplied an ID and it already exists, return existing
    if (dto.id) {
      const existing = await this.prisma.calendarNote.findFirst({
        where: { id: dto.id, deletedAt: null },
        include: {
          media: {
            include: {
              file: true,
            },
            orderBy: {
              order: 'asc',
            },
          },
        },
      });
      if (existing) {
        return existing;
      }
    }

    if (dto.media && dto.media.length > 0) {
      for (const m of dto.media) {
        const file = await this.prisma.file.findFirst({
          where: {
            id: m.fileId,
            uploadedById: userId,
            deletedAt: null,
          },
        });
        if (!file) {
          throw new NotFoundException(`File ${m.fileId} not found`);
        }
      }
    }

    const note = await this.prisma.calendarNote.create({
      data: {
        ...(dto.id ? { id: dto.id } : {}),
        userId,
        ethiopianYear: dto.ethiopianYear,
        ethiopianMonth: dto.ethiopianMonth,
        ethiopianDay: dto.ethiopianDay,
        gregorianDate: new Date(dto.gregorianDate),
        title: dto.title,
        content: dto.content,
        allowDownload: dto.allowDownload ?? false,
        hasReminder: dto.hasReminder ?? false,

        reminderDateTime: dto.reminderDateTime
          ? new Date(dto.reminderDateTime)
          : null,
        reminderNotified: false,
        reminderRepeat: dto.reminderRepeat ?? 'NONE',
        reminderEthiopianMonth: dto.reminderEthiopianMonth,
        reminderEthiopianDay: dto.reminderEthiopianDay,
        reminderHour: dto.reminderHour,
        reminderMinute: dto.reminderMinute,
        reminderTimezone: dto.reminderTimezone ?? 'Africa/Addis_Ababa',
        reminderNextOccurrence: dto.reminderDateTime
          ? new Date(dto.reminderDateTime)
          : null,
        recurrenceType: dto.recurrenceType ?? dto.reminderRepeat ?? 'NONE',
        isAutoPublishEnabled: dto.isAutoPublishEnabled ?? false,
        autoPublishTime: dto.autoPublishTime ?? '12:00',
        ...(dto.media && dto.media.length > 0
          ? {
              media: {
                create: dto.media.map((m) => ({
                  fileId: m.fileId,
                  order: m.order,
                  caption: m.caption,
                })),
              },
            }
          : {}),
      },
      include: {
        media: {
          include: {
            file: true,
          },
          orderBy: {
            order: 'asc',
          },
        },
      },
    });

    // Broadcast to all users (fire-and-forget — never block the response)
    this.notificationsService
      .notifyCalendarNotePublished({
        id: note.id,
        title: note.title,
        content: note.content,
        ethiopianDay: note.ethiopianDay,
        ethiopianMonth: note.ethiopianMonth,
        ethiopianYear: note.ethiopianYear,
      })
      .catch(() => null);

    return note;
  }

  buildRangeWhere(
    startEth: { year: number; month: number; day: number },
    endEth: { year: number; month: number; day: number },
  ) {
    if (startEth.year === endEth.year) {
      if (startEth.month === endEth.month) {
        return {
          ethiopianYear: startEth.year,
          ethiopianMonth: startEth.month,
          ethiopianDay: { gte: startEth.day, lte: endEth.day },
        };
      }
      return {
        ethiopianYear: startEth.year,
        OR: [
          {
            ethiopianMonth: startEth.month,
            ethiopianDay: { gte: startEth.day },
          },
          {
            ethiopianMonth: { gt: startEth.month, lt: endEth.month },
          },
          {
            ethiopianMonth: endEth.month,
            ethiopianDay: { lte: endEth.day },
          },
        ],
      };
    }

    return {
      OR: [
        {
          ethiopianYear: startEth.year,
          OR: [
            {
              ethiopianMonth: startEth.month,
              ethiopianDay: { gte: startEth.day },
            },
            {
              ethiopianMonth: { gt: startEth.month },
            },
          ],
        },
        {
          ethiopianYear: endEth.year,
          OR: [
            {
              ethiopianMonth: { lt: endEth.month },
            },
            {
              ethiopianMonth: endEth.month,
              ethiopianDay: { lte: endEth.day },
            },
          ],
        },
        ...(endEth.year - startEth.year > 1
          ? [
              {
                ethiopianYear: {
                  gt: startEth.year,
                  lt: endEth.year,
                },
              },
            ]
          : []),
      ],
    };
  }

  async findAll(
    queryOrUserId: QueryCalendarNotesDto | string = {},
    maybeQuery?: QueryCalendarNotesDto,
  ) {
    const query: QueryCalendarNotesDto =
      typeof queryOrUserId === 'string' ? (maybeQuery ?? {}) : queryOrUserId;

    const where: any = {};

    if (!query.includeDeleted) {
      where.deletedAt = null;
    }

    // Range filtering takes precedence if provided
    let startEth: { year: number; month: number; day: number } | null = null;
    let endEth: { year: number; month: number; day: number } | null = null;

    if (query.from) {
      startEth = parseEthiopianDate(query.from);
    } else if (query.startYear !== undefined) {
      startEth = {
        year: query.startYear,
        month: query.startMonth ?? 1,
        day: query.startDay ?? 1,
      };
    }

    if (query.to) {
      endEth = parseEthiopianDate(query.to);
    } else if (query.endYear !== undefined) {
      endEth = {
        year: query.endYear,
        month: query.endMonth ?? 13,
        day: query.endDay ?? 30,
      };
    }

    if (startEth && endEth) {
      Object.assign(where, this.buildRangeWhere(startEth, endEth));
    } else {
      if (query.year !== undefined) {
        where.ethiopianYear = query.year;
      }
      if (query.month !== undefined) {
        where.ethiopianMonth = query.month;
      }
      if (query.day !== undefined) {
        where.ethiopianDay = query.day;
      }
    }

    // Incremental sync cursor
    if (query.since) {
      where.updatedAt = { gte: new Date(query.since) };
    }

    return this.prisma.calendarNote.findMany({
      where,
      include: {
        media: {
          include: {
            file: true,
          },
          orderBy: {
            order: 'asc',
          },
        },
        publicationOccurrences: {
          orderBy: { scheduledAt: 'desc' },
          take: 5,
        },
      },
      orderBy: [
        { ethiopianYear: 'desc' },
        { ethiopianMonth: 'desc' },
        { ethiopianDay: 'desc' },
        { createdAt: 'desc' },
      ],
    });
  }

  async syncNotes(query: QueryCalendarNotesDto = {}, userId?: string) {
    const currentEth = getEthiopianDate();
    const rollingWindow = calculateRollingOneYearWindow(currentEth);

    const startEth = query.from
      ? parseEthiopianDate(query.from)
      : query.startYear !== undefined
      ? {
          year: query.startYear,
          month: query.startMonth ?? 1,
          day: query.startDay ?? 1,
        }
      : rollingWindow.start;

    const endEth = query.to
      ? parseEthiopianDate(query.to)
      : query.endYear !== undefined
      ? {
          year: query.endYear,
          month: query.endMonth ?? 13,
          day: query.endDay ?? 30,
        }
      : rollingWindow.end;

    const queryWithRange: QueryCalendarNotesDto = {
      ...query,
      startYear: startEth.year,
      startMonth: startEth.month,
      startDay: startEth.day,
      endYear: endEth.year,
      endMonth: endEth.month,
      endDay: endEth.day,
    };

    const notes = await this.findAll(queryWithRange);

    let deletedIds: string[] = [];
    if (query.since) {
      const deletedNotes = await this.prisma.calendarNote.findMany({
        where: {
          deletedAt: { gte: new Date(query.since) },
          ...this.buildRangeWhere(startEth, endEth),
        },
        select: { id: true },
      });
      deletedIds = deletedNotes.map((n) => n.id);
    }

    // Record sync metadata
    await this.prisma.calendarSyncMetadata
      .create({
        data: {
          userId: userId ?? null,
          activeWindowStart: formatEthiopianDate(
            startEth.year,
            startEth.month,
            startEth.day,
          ),
          activeWindowEnd: formatEthiopianDate(
            endEth.year,
            endEth.month,
            endEth.day,
          ),
          lastSuccessfulSyncAt: new Date(),
          lastSyncCursor: query.since ?? null,
          schemaVersion: 1,
        },
      })
      .catch(() => null);

    return {
      activeWindow: {
        start: formatEthiopianDate(startEth.year, startEth.month, startEth.day),
        end: formatEthiopianDate(endEth.year, endEth.month, endEth.day),
      },
      notes,
      deletedIds,
      serverTime: new Date().toISOString(),
    };
  }

  async findOne(idOrUserId: string, maybeId?: string) {
    const id = maybeId ?? idOrUserId;
    const note = await this.prisma.calendarNote.findFirst({
      where: {
        id,
        deletedAt: null,
      },
      include: {
        media: {
          include: {
            file: true,
          },
          orderBy: {
            order: 'asc',
          },
        },
      },
    });

    if (!note) {
      throw new NotFoundException('Calendar note not found');
    }

    // Publicly readable to all users with calendar access
    return note;
  }

  async update(userId: string, id: string, dto: UpdateCalendarNoteDto) {
    // Verify ownership first
    await this.findOne(userId, id);
    validateReminderRule(dto);

    const updateData: any = {};

    if (dto.ethiopianYear !== undefined) {
      updateData.ethiopianYear = dto.ethiopianYear;
    }
    if (dto.ethiopianMonth !== undefined) {
      updateData.ethiopianMonth = dto.ethiopianMonth;
    }
    if (dto.ethiopianDay !== undefined) {
      updateData.ethiopianDay = dto.ethiopianDay;
    }
    if (dto.gregorianDate !== undefined) {
      updateData.gregorianDate = new Date(dto.gregorianDate);
    }
    if (dto.title !== undefined) {
      updateData.title = dto.title;
    }
    if (dto.content !== undefined) {
      updateData.content = dto.content;
    }
    if (dto.allowDownload !== undefined) {
      updateData.allowDownload = dto.allowDownload;
    }
    if (dto.hasReminder !== undefined) {

      updateData.hasReminder = dto.hasReminder;
      // Reset notification flag when reminder is updated
      updateData.reminderNotified = false;
    }
    if (dto.reminderDateTime !== undefined) {
      updateData.reminderDateTime = dto.reminderDateTime
        ? new Date(dto.reminderDateTime)
        : null;
      // Reset notification flag when reminder time is updated
      updateData.reminderNotified = false;
    }
    if (dto.reminderRepeat !== undefined) {
      updateData.reminderRepeat = dto.reminderRepeat;
      updateData.reminderNotified = false;
    }
    if (dto.reminderEthiopianMonth !== undefined) {
      updateData.reminderEthiopianMonth = dto.reminderEthiopianMonth;
    }
    if (dto.reminderEthiopianDay !== undefined) {
      updateData.reminderEthiopianDay = dto.reminderEthiopianDay;
    }
    if (dto.reminderHour !== undefined)
      updateData.reminderHour = dto.reminderHour;
    if (dto.reminderMinute !== undefined)
      updateData.reminderMinute = dto.reminderMinute;
    if (dto.reminderTimezone !== undefined) {
      updateData.reminderTimezone = dto.reminderTimezone;
    }
    if (dto.recurrenceType !== undefined) {
      updateData.recurrenceType = dto.recurrenceType;
    }
    if (dto.isAutoPublishEnabled !== undefined) {
      updateData.isAutoPublishEnabled = dto.isAutoPublishEnabled;
    }
    if (dto.autoPublishTime !== undefined) {
      updateData.autoPublishTime = dto.autoPublishTime;
    }
    if (dto.reminderRepeat === 'NONE' || dto.hasReminder === false) {
      updateData.reminderNextOccurrence = null;
    } else if (dto.reminderDateTime !== undefined) {
      updateData.reminderNextOccurrence = dto.reminderDateTime
        ? new Date(dto.reminderDateTime)
        : null;
    }

    return this.prisma.calendarNote.update({
      where: { id },
      data: updateData,
      include: {
        media: {
          include: {
            file: true,
          },
          orderBy: {
            order: 'asc',
          },
        },
      },
    });
  }

  async remove(userId: string, id: string) {
    // Verify ownership first
    await this.findOne(userId, id);

    // Soft delete
    return this.prisma.calendarNote.update({
      where: { id },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  async hardDelete(userId: string, id: string) {
    // Verify ownership first
    await this.findOne(userId, id);

    // Hard delete (will cascade to media via Prisma schema)
    return this.prisma.calendarNote.delete({
      where: { id },
    });
  }

  // Media management
  async addMedia(
    userId: string,
    noteId: string,
    fileId: string,
    order: number,
    caption?: string,
  ) {
    // Verify note ownership
    await this.findOne(userId, noteId);

    // Verify file exists and belongs to user
    const file = await this.prisma.file.findFirst({
      where: {
        id: fileId,
        uploadedById: userId,
        deletedAt: null,
      },
    });

    if (!file) {
      throw new NotFoundException('File not found');
    }

    return this.prisma.calendarNoteMedia.create({
      data: {
        noteId,
        fileId,
        order,
        caption,
      },
      include: {
        file: true,
      },
    });
  }

  async updateMedia(
    userId: string,
    noteId: string,
    mediaId: string,
    order?: number,
    caption?: string,
  ) {
    // Verify note ownership
    await this.findOne(userId, noteId);

    // Verify media belongs to note
    const media = await this.prisma.calendarNoteMedia.findFirst({
      where: {
        id: mediaId,
        noteId,
      },
    });

    if (!media) {
      throw new NotFoundException('Media not found');
    }

    const updateData: any = {};
    if (order !== undefined) updateData.order = order;
    if (caption !== undefined) updateData.caption = caption;

    return this.prisma.calendarNoteMedia.update({
      where: { id: mediaId },
      data: updateData,
      include: {
        file: true,
      },
    });
  }

  async removeMedia(userId: string, noteId: string, mediaId: string) {
    // Verify note ownership
    await this.findOne(userId, noteId);

    // Verify media belongs to note
    const media = await this.prisma.calendarNoteMedia.findFirst({
      where: {
        id: mediaId,
        noteId,
      },
    });

    if (!media) {
      throw new NotFoundException('Media not found');
    }

    return this.prisma.calendarNoteMedia.delete({
      where: { id: mediaId },
    });
  }

  // Reminder-specific methods
  async getUpcomingReminders(userId: string, hoursAhead = 24) {
    const now = new Date();
    const futureTime = new Date(now.getTime() + hoursAhead * 60 * 60 * 1000);

    return this.prisma.calendarNote.findMany({
      where: {
        userId,
        deletedAt: null,
        hasReminder: true,
        reminderNotified: false,
        reminderDateTime: {
          gte: now,
          lte: futureTime,
        },
      },
      include: {
        media: {
          include: {
            file: true,
          },
          orderBy: {
            order: 'asc',
          },
        },
      },
      orderBy: {
        reminderDateTime: 'asc',
      },
    });
  }

  async markReminderAsNotified(userId: string, noteId: string) {
    // Verify ownership
    await this.findOne(userId, noteId);

    return this.prisma.calendarNote.update({
      where: { id: noteId },
      data: {
        reminderNotified: true,
      },
    });
  }
}
