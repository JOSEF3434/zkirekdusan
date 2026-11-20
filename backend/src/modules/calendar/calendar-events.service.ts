import {
  Injectable,
  NotFoundException,
  BadRequestException,
  OnModuleInit,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateCalendarEventDto } from './dto/create-calendar-event.dto.js';
import { UpdateCalendarEventDto } from './dto/update-calendar-event.dto.js';
import { QueryCalendarEventsDto } from './dto/query-calendar-events.dto.js';
import { EOTC_DEFAULT_EVENTS } from './calendar-events.seed.js';
import {
  getDaysInEthiopianMonth,
  getEventMonthDaysCoverage,
  doesEventOverlapMonth,
  calculateEventDuration,
  ethiopianToGregorian,
  formatEthiopianDate,
  calculateBahireHasab,
  getMovableEventsForYear,
  getWednesdayFridayFastDaysForMonth,
} from './calendar-ethiopian.util.js';

@Injectable()
export class CalendarEventsService implements OnModuleInit {
  private readonly logger = new Logger(CalendarEventsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    await this.seedDefaultEventsIfEmpty();
  }

  /**
   * Seeds default Ethiopian Orthodox fasting and holiday events if the table is empty.
   */
  async seedDefaultEventsIfEmpty(): Promise<void> {
    try {
      this.logger.log('Syncing default canonical Ethiopian Orthodox fasts and holidays...');
      for (const item of EOTC_DEFAULT_EVENTS) {
        const existing = await this.prisma.calendarEvent.findFirst({
          where: {
            name: item.name,
            startMonth: item.startMonth,
            startDay: item.startDay,
            deletedAt: null,
          },
        });
        if (!existing) {
          await this.prisma.calendarEvent.create({
            data: {
              name: item.name,
              nameEn: item.nameEn,
              type: item.type,
              category: item.category,
              isRecurring: item.isRecurring,
              ethiopianYear: item.ethiopianYear,
              startMonth: item.startMonth,
              startDay: item.startDay,
              endMonth: item.endMonth,
              endDay: item.endDay,
              description: item.description,
              spiritualMeaning: item.spiritualMeaning,
              fastingRules: item.fastingRules,
              primaryColor: item.primaryColor,
              isMajor: item.isMajor,
              importance: item.importance ?? (item.isMajor ? 'MAJOR' : 'NORMAL'),
              isActive: item.isActive,
            },
          });
        }
      }
      this.logger.log('Canonical calendar events synchronization completed.');
    } catch (err) {
      this.logger.warn(`Could not seed default events (migration or db might not be ready yet): ${err}`);
    }
  }

  /**
   * Validates date boundaries, leap-year Pagume lengths, and logical ranges.
   */
  private validateEventDates(dto: {
    isRecurring?: boolean;
    ethiopianYear?: number;
    startMonth: number;
    startDay: number;
    endMonth: number;
    endDay: number;
  }) {
    if (dto.startMonth < 1 || dto.startMonth > 13) {
      throw new BadRequestException('Start month must be between 1 and 13');
    }
    if (dto.endMonth < 1 || dto.endMonth > 13) {
      throw new BadRequestException('End month must be between 1 and 13');
    }

    const testYear = dto.ethiopianYear ?? 2017;
    const maxStartDays = getDaysInEthiopianMonth(testYear, dto.startMonth);
    const maxEndDays = getDaysInEthiopianMonth(testYear, dto.endMonth);

    if (dto.startDay < 1 || dto.startDay > maxStartDays) {
      throw new BadRequestException(
        `Start day must be between 1 and ${maxStartDays} for month ${dto.startMonth}`,
      );
    }
    if (dto.endDay < 1 || dto.endDay > maxEndDays) {
      throw new BadRequestException(
        `End day must be between 1 and ${maxEndDays} for month ${dto.endMonth}`,
      );
    }

    if (dto.isRecurring === false && !dto.ethiopianYear) {
      throw new BadRequestException(
        'Specific Ethiopian year is required when isRecurring is false',
      );
    }

    // If same month and same year (or recurring), start day must be <= end day
    const sYear = (dto as any).startYear;
    const eYear = (dto as any).endYear;
    if (dto.startMonth === dto.endMonth && (sYear == null || eYear == null || sYear === eYear)) {
      if (dto.startDay > dto.endDay) {
        throw new BadRequestException('Start day cannot be after end day in the same month');
      }
    }
  }

  /**
   * Formats event with calculated runtime metadata (duration, Gregorian dates, etc.).
   */
  private formatEventMetadata(event: any, referenceYear: number) {
    const startYear = event.startYear ?? event.ethiopianYear ?? referenceYear;
    let endYear = event.endYear ?? event.ethiopianYear ?? referenceYear;
    if (event.isRecurring && event.startMonth > event.endMonth) {
      endYear = startYear + 1;
    }

    const durationDays = calculateEventDuration(
      startYear,
      event.startMonth,
      event.startDay,
      endYear,
      event.endMonth,
      event.endDay,
    );

    const startGregorian = ethiopianToGregorian(startYear, event.startMonth, event.startDay);
    const endGregorian = ethiopianToGregorian(endYear, event.endMonth, event.endDay);

    const isMajor = event.isMajor ?? ((event as any).importance === 'MAJOR');
    const importance = (event as any).importance ?? (isMajor ? 'MAJOR' : 'NORMAL');

    return {
      ...event,
      isMajor,
      importance,
      durationDays,
      startEthiopianDateFormatted: formatEthiopianDate(startYear, event.startMonth, event.startDay),
      endEthiopianDateFormatted: formatEthiopianDate(endYear, event.endMonth, event.endDay),
      startGregorianDate: startGregorian.toISOString(),
      endGregorianDate: endGregorian.toISOString(),
    };
  }

  /**
   * Retrieves all events matching query filters (admin list or general view).
   */
  async findAll(query: QueryCalendarEventsDto) {
    const where: any = {
      deletedAt: null,
    };

    if (!query.includeInactive) {
      where.isActive = true;
    }

    if (query.type) {
      where.type = query.type;
    }

    if (query.category) {
      where.category = query.category;
    }

    if (query.isMajor !== undefined) {
      where.isMajor = query.isMajor;
    }

    if (query.importance) {
      where.importance = query.importance;
    }

    if (query.search) {
      where.OR = [
        { name: { contains: query.search, mode: 'insensitive' } },
        { nameEn: { contains: query.search, mode: 'insensitive' } },
        { description: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    if (query.year) {
      where.OR = [
        ...(where.OR || []),
        { isRecurring: true },
        { ethiopianYear: query.year },
      ];
    }

    const events = await this.prisma.calendarEvent.findMany({
      where,
      orderBy: [{ startMonth: 'asc' }, { startDay: 'asc' }, { name: 'asc' }],
    });

    const refYear = query.year ?? 2017;
    let allEvents: any[] = [...events];
    if (query.year) {
      const movable = getMovableEventsForYear(query.year);
      for (const mov of movable) {
        const exists = events.some(
          (e) =>
            e.name === mov.name &&
            (e.ethiopianYear === query.year || e.startYear === query.year),
        );
        if (!exists) {
          allEvents.push(mov);
        }
      }
      if (query.type) {
        allEvents = allEvents.filter((e) => e.type === query.type);
      }
      if (query.category) {
        allEvents = allEvents.filter((e) => e.category === query.category);
      }
      if (query.isMajor !== undefined) {
        allEvents = allEvents.filter((e) => e.isMajor === query.isMajor);
      }
      if (query.importance) {
        allEvents = allEvents.filter((e) => e.importance === query.importance);
      }
      if (query.search) {
        const s = query.search.toLowerCase();
        allEvents = allEvents.filter(
          (e) =>
            (e.name && e.name.toLowerCase().includes(s)) ||
            (e.nameEn && e.nameEn.toLowerCase().includes(s)) ||
            (e.description && e.description.toLowerCase().includes(s)),
        );
      }
    }

    return allEvents.map((e) => this.formatEventMetadata(e, refYear));
  }

  /**
   * Retrieves events overlapping with a specific Ethiopian year and month.
   */
  async getEventsForMonth(year: number, month: number) {
    if (month < 1 || month > 13) {
      throw new BadRequestException('Month must be between 1 and 13');
    }

    // Fetch active events that are recurring OR belong to this specific year
    const events = await this.prisma.calendarEvent.findMany({
      where: {
        deletedAt: null,
        isActive: true,
        OR: [
          { isRecurring: true },
          { ethiopianYear: year },
          { AND: [{ startYear: { lte: year } }, { endYear: { gte: year } }] },
        ],
      },
      orderBy: [{ startMonth: 'asc' }, { startDay: 'asc' }],
    });

    // Merge calculated movable events for this year (if not customized in DB)
    const movableEvents = getMovableEventsForYear(year);
    const combinedEvents: any[] = [...events];
    for (const mov of movableEvents) {
      const existsInDb = events.some(
        (e) => e.name === mov.name && (e.ethiopianYear === year || e.startYear === year),
      );
      if (!existsInDb) {
        combinedEvents.push(mov);
      }
    }

    // Filter by actual month overlap and decorate with monthly coverage
    const monthEvents = combinedEvents
      .filter((e) => doesEventOverlapMonth(e, year, month))
      .map((e) => {
        const coverage = getEventMonthDaysCoverage(e, year, month);
        const formatted = this.formatEventMetadata(e, year);
        return {
          ...formatted,
          coverage,
        };
      });

    // Add recurring Wednesday & Friday fast (ጾመ ድኅነት) with month-specific coverage
    const wedFriDays = getWednesdayFridayFastDaysForMonth(year, month);
    if (wedFriDays.length > 0) {
      const isStartMonth = month === 1;
      const isEndMonth = month === 13;
      monthEvents.push({
        id: `wed-fri-fast-${year}-${month}`,
        name: 'ጾመ ድኅነት (የረቡዕ እና የዓርብ ጾም)',
        nameEn: 'Fast of Salvation (Wednesday & Friday Fast)',
        type: 'FAST',
        category: 'MAJOR_FAST',
        isRecurring: true,
        isMajor: true,
        importance: 'MAJOR',
        primaryColor: '#F59E0B',
        startMonth: 1,
        startDay: 1,
        endMonth: 13,
        endDay: 6,
        description:
          'ዓመቱን ሙሉ በየሳምንቱ የሚጾም የረቡዕ (የጌታችን የመያዝ ምክር) እና የዓርብ (የስቅለቱ መታሰቢያ) ጾም። ከትንሣኤ እስከ ጰራቅሊጦስ ባሉት ፶ ቀናት (በዓለ ኀምሳ) እና በገና/ጥምቀት በዓላት ወቅት ጾሙ ይፈሰካል።',
        spiritualMeaning:
          'በየሳምንቱ የጌታችንን ሕማማት እና በመስቀል ላይ የፈጸመውን የዘላለም ድኅነት የምንዘክርበት ታላቅ ጾም።',
        fastingRules: 'ከእንስሳት ተዋጽኦ መከልከል፣ እስከ ቀትር/፱ ሰዓት መጾም።',
        durationDays: wedFriDays.length,
        isActive: true,
        startEthiopianDateFormatted: formatEthiopianDate(year, month, wedFriDays[0]),
        endEthiopianDateFormatted: formatEthiopianDate(
          year,
          month,
          wedFriDays[wedFriDays.length - 1],
        ),
        startGregorianDate: ethiopianToGregorian(year, month, wedFriDays[0]).toISOString(),
        endGregorianDate: ethiopianToGregorian(
          year,
          month,
          wedFriDays[wedFriDays.length - 1],
        ).toISOString(),
        coverage: {
          overlaps: true,
          days: wedFriDays,
          isStartMonth,
          isEndMonth,
          startDay: wedFriDays[0],
          endDay: wedFriDays[wedFriDays.length - 1],
          durationDays: wedFriDays.length,
        },
      });
    }

    return monthEvents;
  }

  /**
   * Retrieves all events for an Ethiopian year, organized chronologically.
   */
  async getEventsForYear(year: number) {
    const events = await this.prisma.calendarEvent.findMany({
      where: {
        deletedAt: null,
        isActive: true,
        OR: [
          { isRecurring: true },
          { ethiopianYear: year },
          { AND: [{ startYear: { lte: year } }, { endYear: { gte: year } }] },
        ],
      },
      orderBy: [{ startMonth: 'asc' }, { startDay: 'asc' }],
    });

    // Merge calculated movable events for this year
    const movableEvents = getMovableEventsForYear(year);
    const combinedEvents: any[] = [...events];
    for (const mov of movableEvents) {
      const existsInDb = events.some(
        (e) => e.name === mov.name && (e.ethiopianYear === year || e.startYear === year),
      );
      if (!existsInDb) {
        combinedEvents.push(mov);
      }
    }

    // Sort chronologically by startMonth, startDay, then name
    combinedEvents.sort((a, b) => {
      if (a.startMonth !== b.startMonth) return a.startMonth - b.startMonth;
      if (a.startDay !== b.startDay) return a.startDay - b.startDay;
      return (a.name || '').localeCompare(b.name || '');
    });

    return combinedEvents.map((e) => this.formatEventMetadata(e, year));
  }

  /**
   * Retrieves events active on a specific Ethiopian date (day, month, year).
   */
  async getEventsForDay(year: number, month: number, day: number) {
    const monthEvents = await this.getEventsForMonth(year, month);
    return monthEvents
      .filter((e) => e.coverage.days.includes(day))
      .map((e) => {
        const isStart = e.coverage.isStartMonth && e.startDay === day;
        const isEnd = e.coverage.isEndMonth && e.endDay === day;
        return {
          ...e,
          dayRole: isStart && isEnd
            ? 'SINGLE_DAY'
            : isStart
              ? 'FAST_BEGINNING'
              : isEnd
                ? 'FAST_ENDING'
                : 'ONGOING',
        };
      });
  }

  /**
   * Retrieves a single event by ID.
   */
  async findOne(id: string) {
    const event = await this.prisma.calendarEvent.findFirst({
      where: { id, deletedAt: null },
    });
    if (!event) {
      throw new NotFoundException(`Calendar event ${id} not found`);
    }
    return this.formatEventMetadata(event, event.ethiopianYear ?? 2017);
  }

  /**
   * Creates a new fasting period or holiday.
   */
  async create(userId: string, dto: CreateCalendarEventDto) {
    this.validateEventDates(dto);

    // Duplicate check for identical name in same year/recurring status
    const existing = await this.prisma.calendarEvent.findFirst({
      where: {
        name: dto.name,
        isRecurring: dto.isRecurring ?? true,
        ethiopianYear: dto.ethiopianYear ?? null,
        deletedAt: null,
      },
    });
    if (existing) {
      throw new BadRequestException(
        `An event with name "${dto.name}" already exists for this timeframe.`,
      );
    }

    const isMajor = dto.isMajor ?? (dto.importance === 'MAJOR');
    const importance = dto.importance ?? (isMajor ? 'MAJOR' : 'NORMAL');

    let primaryColor = dto.primaryColor;
    if (!primaryColor || primaryColor.trim() === '') {
      if (dto.type === 'FAST') {
        primaryColor = '#F59E0B'; // Orange default for fasting period
      } else if (dto.type === 'HOLIDAY' && isMajor) {
        primaryColor = '#DC2626'; // Red default for major holiday
      } else if (dto.type === 'SPECIAL_EVENT' || importance === 'SPECIAL') {
        primaryColor = '#16A34A'; // Green default for special event
      } else {
        primaryColor = '#F59E0B';
      }
    }

    const created = await this.prisma.calendarEvent.create({
      data: {
        name: dto.name,
        nameEn: dto.nameEn,
        type: dto.type,
        category: dto.category,
        isRecurring: dto.isRecurring ?? true,
        ethiopianYear: dto.isRecurring === false ? dto.ethiopianYear : null,
        startMonth: dto.startMonth,
        startDay: dto.startDay,
        startYear: dto.startYear,
        endMonth: dto.endMonth,
        endDay: dto.endDay,
        endYear: dto.endYear,
        description: dto.description,
        spiritualMeaning: dto.spiritualMeaning,
        fastingRules: dto.fastingRules,
        primaryColor,
        icon: dto.icon,
        isMajor,
        importance,
        isActive: dto.isActive ?? true,
        createdById: userId,
      },
    });

    return this.formatEventMetadata(created, created.ethiopianYear ?? 2017);
  }

  /**
   * Updates an existing event.
   */
  async update(userId: string, id: string, dto: UpdateCalendarEventDto) {
    const existing = await this.prisma.calendarEvent.findFirst({
      where: { id, deletedAt: null },
    });
    if (!existing) {
      throw new NotFoundException(`Calendar event ${id} not found`);
    }

    const merged = {
      isRecurring: dto.isRecurring ?? existing.isRecurring,
      ethiopianYear: dto.ethiopianYear !== undefined ? dto.ethiopianYear : existing.ethiopianYear ?? undefined,
      startMonth: dto.startMonth ?? existing.startMonth,
      startDay: dto.startDay ?? existing.startDay,
      endMonth: dto.endMonth ?? existing.endMonth,
      endDay: dto.endDay ?? existing.endDay,
    };
    this.validateEventDates(merged);

    const updated = await this.prisma.calendarEvent.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name } : {}),
        ...(dto.nameEn !== undefined ? { nameEn: dto.nameEn } : {}),
        ...(dto.type !== undefined ? { type: dto.type } : {}),
        ...(dto.category !== undefined ? { category: dto.category } : {}),
        ...(dto.isRecurring !== undefined ? { isRecurring: dto.isRecurring } : {}),
        ...(dto.ethiopianYear !== undefined ? { ethiopianYear: dto.ethiopianYear } : {}),
        ...(dto.startMonth !== undefined ? { startMonth: dto.startMonth } : {}),
        ...(dto.startDay !== undefined ? { startDay: dto.startDay } : {}),
        ...(dto.startYear !== undefined ? { startYear: dto.startYear } : {}),
        ...(dto.endMonth !== undefined ? { endMonth: dto.endMonth } : {}),
        ...(dto.endDay !== undefined ? { endDay: dto.endDay } : {}),
        ...(dto.endYear !== undefined ? { endYear: dto.endYear } : {}),
        ...(dto.description !== undefined ? { description: dto.description } : {}),
        ...(dto.spiritualMeaning !== undefined ? { spiritualMeaning: dto.spiritualMeaning } : {}),
        ...(dto.fastingRules !== undefined ? { fastingRules: dto.fastingRules } : {}),
        ...(dto.primaryColor !== undefined ? { primaryColor: dto.primaryColor } : {}),
        ...(dto.icon !== undefined ? { icon: dto.icon } : {}),
        ...(dto.isMajor !== undefined
          ? { isMajor: dto.isMajor }
          : dto.importance === 'MAJOR'
            ? { isMajor: true }
            : {}),
        ...(dto.importance !== undefined ? { importance: dto.importance } : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
    });

    return this.formatEventMetadata(updated, updated.ethiopianYear ?? 2017);
  }

  /**
   * Soft deletes an event.
   */
  async remove(userId: string, id: string) {
    const existing = await this.prisma.calendarEvent.findFirst({
      where: { id, deletedAt: null },
    });
    if (!existing) {
      throw new NotFoundException(`Calendar event ${id} not found`);
    }

    await this.prisma.calendarEvent.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    return { success: true, message: 'Calendar event removed successfully' };
  }

  /**
   * Toggles active / inactive status of an event.
   */
  async toggleStatus(userId: string, id: string) {
    const existing = await this.prisma.calendarEvent.findFirst({
      where: { id, deletedAt: null },
    });
    if (!existing) {
      throw new NotFoundException(`Calendar event ${id} not found`);
    }

    const updated = await this.prisma.calendarEvent.update({
      where: { id },
      data: { isActive: !existing.isActive },
    });

    return this.formatEventMetadata(updated, updated.ethiopianYear ?? 2017);
  }
}
