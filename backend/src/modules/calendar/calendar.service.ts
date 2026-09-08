import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateCalendarNoteDto } from './dto/create-calendar-note.dto.js';
import { UpdateCalendarNoteDto } from './dto/update-calendar-note.dto.js';
import { QueryCalendarNotesDto } from './dto/query-calendar-notes.dto.js';

@Injectable()
export class CalendarService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateCalendarNoteDto) {
    return this.prisma.calendarNote.create({
      data: {
        userId,
        ethiopianYear: dto.ethiopianYear,
        ethiopianMonth: dto.ethiopianMonth,
        ethiopianDay: dto.ethiopianDay,
        gregorianDate: new Date(dto.gregorianDate),
        title: dto.title,
        content: dto.content,
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
  }

  async findAll(userId: string, query: QueryCalendarNotesDto) {
    const where: any = {
      userId,
      deletedAt: null,
    };

    if (query.year !== undefined) {
      where.ethiopianYear = query.year;
    }

    if (query.month !== undefined) {
      where.ethiopianMonth = query.month;
    }

    if (query.day !== undefined) {
      where.ethiopianDay = query.day;
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
      },
      orderBy: [
        { ethiopianYear: 'desc' },
        { ethiopianMonth: 'desc' },
        { ethiopianDay: 'desc' },
        { createdAt: 'desc' },
      ],
    });
  }

  async findOne(userId: string, id: string) {
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

    // Check ownership
    if (note.userId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    return note;
  }

  async update(userId: string, id: string, dto: UpdateCalendarNoteDto) {
    // Verify ownership first
    await this.findOne(userId, id);

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
}
