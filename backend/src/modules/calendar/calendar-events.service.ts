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

    // Filter by actual month overlap and decorate with monthly coverage.
    // Exclude annual template/placeholder for Wednesday & Friday fasts, as it is computed per-month with active fast days.
    const monthEvents = combinedEvents
      .filter(
        (e) =>
          !e.name.includes('ጾመ ድኅነት') &&
          !e.name.includes('Wednesday & Friday Fast') &&
          e.id !== 'fast-wed-fri',
      )
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
        startMonth: month,
        startDay: wedFriDays[0],
        endMonth: month,
        endDay: wedFriDays[wedFriDays.length - 1],
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
          isStartMonth: false,
          isEndMonth: false,
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
   * Known alias mapping from client/builtin/movable identifiers to Ethiopian canonical event names.
   */
  private readonly CANONICAL_ID_ALIASES: Record<string, string> = {
    'builtin-fast-prophets': 'ጾመ ነቢያት (የገና ጾም)',
    'builtin-fast-sibket': 'ጾመ ስቢይ (ጾመ ስብከት)',
    'builtin-fast-filseta': 'ጾመ ፍልሰታ',
    'builtin-fast-gahad-genna': 'ጾመ ገሃድ (የገና ገሃድ)',
    'builtin-fast-gahad-timkat': 'ጾመ ገሃድ (የጥምቀት ገሃድ)',
    'builtin-wed-fri': 'ጾመ ድኅነት (የረቡዕ እና የዓርብ ጾም)',
    'fast-wed-fri': 'ጾመ ድኅነት (የረቡዕ እና የዓርብ ጾም)',
    'builtin-tsinset': 'ጽንሰት (በዓለ ጽንሰት)',
    'builtin-genna': 'ልደት (የገና በዓል)',
    'builtin-timkat': 'ጥምቀት (ኤጲፋንያ)',
    'builtin-debre-tabor': 'ደብረ ታቦር (ቡሄ)',
    'builtin-ketera': 'ከተራ',
    'builtin-kana': 'ቃና ዘገሊላ',
    'builtin-gizret': 'ግዝረት (የጌታችን ግዝረት)',
    'builtin-zemene-sibket': 'ዘመነ ስብከት',
    'builtin-zemene-berhan': 'ዘመነ ብርሃን',
    'builtin-zemene-nolawi': 'ዘመነ ኖላዊ',
    'builtin-meskel': 'መስቀል (ደመራ)',
    'builtin-ginhete-meskel': 'ግንፈተ መስቀል',
    'builtin-filseta-maryam': 'ዕርገተ ማርያም (ፍልሰታ)',
    'builtin-asteroeyo-maryam': 'አስተርእዮ ማርያም',
    'builtin-lideta-maryam': 'ልደታ ለማርያም',
    'builtin-tsion-maryam': 'ጽዮን ማርያም',
    'builtin-baata-maryam': 'በዓታ ለማርያም',
    'builtin-kidane-mehret': 'ኪዳነ ምሕረት',
    'builtin-debre-mitmaq': 'ደብረ ምጥማቅ',
    'builtin-qusquam': 'ቁስቋም ማርያም',
    'builtin-enkutatash': 'እንቁጣጣሽ (አዲስ ዓመት)',
    'builtin-yohannes-metmiq-birth': 'ልደተ ዮሐንስ መጥምቅ',
    'builtin-michael-hidar': 'ኅዳር ሚካኤል',
    'builtin-michael-sene': 'ሰኔ ሚካኤል',
    'builtin-gabriel-kulubi': 'ታኅሣሥ ገብርኤል (ቁልቢ)',
    'builtin-gabriel-hamle': 'ሐምሌ ገብርኤል',
    'builtin-rufael': 'ጳጉሜን ሩፋኤል',
    'builtin-urael': 'ጥር ዑራኤል',
    'builtin-silassie-hidar': 'ኅዳር ሥላሴ',
    'builtin-silassie-hamle': 'ሐምሌ ሥላሴ',
    'builtin-giorgis-miazia': 'ሚያዝያ ጊዮርጊስ',
    'builtin-giorgis-hidar': 'ኅዳር ጊዮርጊስ',
    'builtin-teklehaymanot-nehase': 'ነሐሴ ተክለ ሃይማኖት',
    'builtin-teklehaymanot-tahsiss': 'ታኅሣሥ ተክለ ሃይማኖት',
    'builtin-abo-megabit': 'መጋቢት ገብረ መንፈስ ቅዱስ (አቦ)',
    'builtin-abo-tikimt': 'ጥቅምት ገብረ መንፈስ ቅዱስ (አቦ)',
    'builtin-estifanos': 'ቅዱስ እስጢፋኖስ',
    'builtin-medhanealem-hidar': 'ኅዳር መድኃኔዓለም',
    'builtin-medhanealem-megabit': 'መጋቢት መድኃኔዓለም',
    'builtin-emmanuel': 'ታኅሣሥ አማኑኤል',
    'builtin-peter-paul': 'ጴጥሮስ ወጳውሎስ',
    'builtin-aregawi': 'አቡነ አረጋዊ',
  };

  /**
   * Resolves a built-in canonical or movable template by ID or alias.
   */
  private resolveCanonicalTemplate(id: string): any | null {
    if (!id) return null;

    // 1. Direct match in EOTC_DEFAULT_EVENTS
    const exactSeed = EOTC_DEFAULT_EVENTS.find((e) => (e as any).id === id || e.name === id);
    if (exactSeed) return exactSeed;

    // 2. Check alias map
    const aliasName = this.CANONICAL_ID_ALIASES[id];
    if (aliasName) {
      const match = EOTC_DEFAULT_EVENTS.find((e) => e.name === aliasName);
      if (match) return match;
    }

    // 3. Builtin Wednesday & Friday fasts
    if (id.includes('wed-fri')) {
      const wedFriSeed = EOTC_DEFAULT_EVENTS.find(
        (e) => e.name.includes('ድኅነት') || e.name.includes('የረቡዕ እና የዓርብ'),
      );
      if (wedFriSeed) return wedFriSeed;
    }

    // 4. Movable events (e.g. movable-nenewe-2019, movable-abiy-tsom-2019)
    if (id.startsWith('movable-')) {
      const parts = id.split('-');
      const yearStr = parts[parts.length - 1];
      const parsedYear = parseInt(yearStr, 10);
      const year = !isNaN(parsedYear) && parsedYear > 1900 && parsedYear < 2200 ? parsedYear : 2017;
      const movables = getMovableEventsForYear(year);
      const matchedMovable = movables.find((m) => m.id === id);
      if (matchedMovable) return matchedMovable;

      const key = id.replace(/^movable-/, '').replace(/-\d+$/, '');
      const byKey = movables.find((m) => m.id.includes(key) || m.nameEn?.toLowerCase().includes(key));
      if (byKey) return byKey;
    }

    // 5. Partial name match in default seeds
    const lowerId = id.toLowerCase();
    const partialMatch = EOTC_DEFAULT_EVENTS.find(
      (e) =>
        e.name.toLowerCase() === lowerId ||
        (e.nameEn && e.nameEn.toLowerCase() === lowerId),
    );
    if (partialMatch) return partialMatch;

    return null;
  }

  /**
   * Retrieves a single event by ID.
   */
  async findOne(id: string) {
    let event = await this.prisma.calendarEvent.findFirst({
      where: { id, deletedAt: null },
    });
    if (!event) {
      const template = this.resolveCanonicalTemplate(id);
      if (template) {
        event = await this.prisma.calendarEvent.findFirst({
          where: { name: template.name, deletedAt: null },
        });
        if (event) {
          return this.formatEventMetadata(event, event.ethiopianYear ?? 2017);
        }
        return this.formatEventMetadata(template, template.ethiopianYear ?? 2017);
      }
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
   * Updates an existing event, or upserts if updating a canonical/movable built-in event.
   */
  async update(userId: string, id: string, dto: UpdateCalendarEventDto) {
    let existing = await this.prisma.calendarEvent.findFirst({
      where: { id, deletedAt: null },
    });

    if (!existing) {
      // Check if there is an existing event in DB by matching canonical name or dto name
      const template = this.resolveCanonicalTemplate(id);
      const targetName = dto.name || template?.name;
      if (targetName) {
        existing = await this.prisma.calendarEvent.findFirst({
          where: {
            name: targetName,
            deletedAt: null,
            ...(dto.ethiopianYear ? { ethiopianYear: dto.ethiopianYear } : {}),
          },
        });
      }

      if (!existing && template) {
        // Create new record from template + dto
        const isMajor = dto.isMajor ?? (dto.importance === 'MAJOR') ?? template.isMajor ?? false;
        const importance = dto.importance ?? (isMajor ? 'MAJOR' : (template.importance ?? 'NORMAL'));
        const created = await this.prisma.calendarEvent.create({
          data: {
            id,
            name: dto.name ?? template.name,
            nameEn: dto.nameEn ?? template.nameEn,
            type: dto.type ?? template.type,
            category: dto.category ?? template.category,
            isRecurring: dto.isRecurring ?? template.isRecurring ?? true,
            ethiopianYear: dto.ethiopianYear !== undefined ? dto.ethiopianYear : template.ethiopianYear ?? null,
            startMonth: dto.startMonth ?? template.startMonth,
            startDay: dto.startDay ?? template.startDay,
            startYear: dto.startYear ?? template.startYear,
            endMonth: dto.endMonth ?? template.endMonth,
            endDay: dto.endDay ?? template.endDay,
            endYear: dto.endYear ?? template.endYear,
            description: dto.description !== undefined ? dto.description : template.description,
            spiritualMeaning: dto.spiritualMeaning !== undefined ? dto.spiritualMeaning : template.spiritualMeaning,
            fastingRules: dto.fastingRules !== undefined ? dto.fastingRules : template.fastingRules,
            primaryColor: dto.primaryColor ?? template.primaryColor ?? '#F59E0B',
            icon: dto.icon ?? template.icon,
            isMajor,
            importance,
            isActive: dto.isActive !== undefined ? dto.isActive : template.isActive,
            createdById: userId,
          },
        });
        return this.formatEventMetadata(created, created.ethiopianYear ?? 2017);
      } else if (!existing && !template && dto.name && dto.startMonth && dto.startDay && dto.endMonth && dto.endDay) {
        return this.create(userId, dto as any);
      }

      if (!existing) {
        throw new NotFoundException(`Calendar event ${id} not found`);
      }
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
      where: { id: existing.id },
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
    let existing = await this.prisma.calendarEvent.findFirst({
      where: { id, deletedAt: null },
    });
    if (!existing) {
      const template = this.resolveCanonicalTemplate(id);
      if (template) {
        await this.prisma.calendarEvent.create({
          data: {
            id,
            name: template.name,
            nameEn: template.nameEn,
            type: template.type,
            category: template.category,
            isRecurring: template.isRecurring ?? true,
            ethiopianYear: template.ethiopianYear,
            startMonth: template.startMonth,
            startDay: template.startDay,
            endMonth: template.endMonth,
            endDay: template.endDay,
            primaryColor: template.primaryColor ?? '#F59E0B',
            isMajor: template.isMajor ?? false,
            importance: template.importance ?? 'NORMAL',
            isActive: false,
            deletedAt: new Date(),
            createdById: userId,
          },
        });
        return { success: true, message: 'Calendar event removed successfully' };
      }
      throw new NotFoundException(`Calendar event ${id} not found`);
    }

    await this.prisma.calendarEvent.update({
      where: { id: existing.id },
      data: { deletedAt: new Date(), isActive: false },
    });

    return { success: true, message: 'Calendar event removed successfully' };
  }

  /**
   * Toggles active / inactive status of an event, creating it if it was a built-in canonical event.
   */
  async toggleStatus(userId: string, id: string) {
    let existing = await this.prisma.calendarEvent.findFirst({
      where: { id, deletedAt: null },
    });

    if (!existing) {
      const template = this.resolveCanonicalTemplate(id);
      if (template) {
        existing = await this.prisma.calendarEvent.findFirst({
          where: {
            name: template.name,
            deletedAt: null,
            ...(template.ethiopianYear ? { ethiopianYear: template.ethiopianYear } : {}),
          },
        });
      }

      if (existing) {
        const updated = await this.prisma.calendarEvent.update({
          where: { id: existing.id },
          data: { isActive: !existing.isActive },
        });
        return this.formatEventMetadata(updated, updated.ethiopianYear ?? 2017);
      }

      if (template) {
        const created = await this.prisma.calendarEvent.create({
          data: {
            id,
            name: template.name,
            nameEn: template.nameEn,
            type: template.type,
            category: template.category,
            isRecurring: template.isRecurring ?? true,
            ethiopianYear: template.ethiopianYear ?? null,
            startMonth: template.startMonth,
            startDay: template.startDay,
            endMonth: template.endMonth,
            endDay: template.endDay,
            description: template.description,
            spiritualMeaning: template.spiritualMeaning,
            fastingRules: template.fastingRules,
            primaryColor: template.primaryColor ?? '#F59E0B',
            isMajor: template.isMajor ?? false,
            importance: template.importance ?? (template.isMajor ? 'MAJOR' : 'NORMAL'),
            isActive: !template.isActive,
            createdById: userId,
          },
        });
        return this.formatEventMetadata(created, created.ethiopianYear ?? 2017);
      }

      throw new NotFoundException(`Calendar event ${id} not found`);
    }

    const updated = await this.prisma.calendarEvent.update({
      where: { id: existing.id },
      data: { isActive: !existing.isActive },
    });

    return this.formatEventMetadata(updated, updated.ethiopianYear ?? 2017);
  }
}
