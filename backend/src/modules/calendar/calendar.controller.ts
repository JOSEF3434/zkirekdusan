import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { CalendarService } from './calendar.service.js';
import { CreateCalendarNoteDto } from './dto/create-calendar-note.dto.js';
import { UpdateCalendarNoteDto } from './dto/update-calendar-note.dto.js';
import { QueryCalendarNotesDto } from './dto/query-calendar-notes.dto.js';
import { AddNoteMediaDto } from './dto/add-note-media.dto.js';
import { UpdateNoteMediaDto } from './dto/update-note-media.dto.js';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Calendar')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('calendar/notes')
export class CalendarController {
  constructor(private readonly calendarService: CalendarService) {}

  @Post()
  @Roles(AppRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Create a calendar note' })
  create(
    @CurrentUser('sub') userId: string,
    @Body() createDto: CreateCalendarNoteDto,
  ) {
    return this.calendarService.create(userId, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get calendar notes (with optional filters)' })
  findAll(
    @Query() query: QueryCalendarNotesDto,
  ) {
    return this.calendarService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific calendar note' })
  findOne(@Param('id') id: string) {
    return this.calendarService.findOne(id);
  }

  @Patch(':id')
  @Roles(AppRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Update a calendar note' })
  update(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() updateDto: UpdateCalendarNoteDto,
  ) {
    return this.calendarService.update(userId, id, updateDto);
  }

  @Delete(':id')
  @Roles(AppRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Delete a calendar note (soft delete)' })
  remove(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    return this.calendarService.remove(userId, id);
  }

  // Media endpoints
  @Post(':noteId/media')
  @Roles(AppRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Add media to a calendar note' })
  addMedia(
    @CurrentUser('sub') userId: string,
    @Param('noteId') noteId: string,
    @Body() dto: AddNoteMediaDto,
  ) {
    return this.calendarService.addMedia(
      userId,
      noteId,
      dto.fileId,
      dto.order,
      dto.caption,
    );
  }

  @Patch(':noteId/media/:mediaId')
  @Roles(AppRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Update note media order/caption' })
  updateMedia(
    @CurrentUser('sub') userId: string,
    @Param('noteId') noteId: string,
    @Param('mediaId') mediaId: string,
    @Body() dto: UpdateNoteMediaDto,
  ) {
    return this.calendarService.updateMedia(
      userId,
      noteId,
      mediaId,
      dto.order,
      dto.caption,
    );
  }

  @Delete(':noteId/media/:mediaId')
  @Roles(AppRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Remove media from calendar note' })
  removeMedia(
    @CurrentUser('sub') userId: string,
    @Param('noteId') noteId: string,
    @Param('mediaId') mediaId: string,
  ) {
    return this.calendarService.removeMedia(userId, noteId, mediaId);
  }

  // Reminder endpoints
  @Get('reminders/upcoming')
  @ApiOperation({ summary: 'Get upcoming reminders (next 24 hours)' })
  getUpcomingReminders(@CurrentUser('sub') userId: string) {
    return this.calendarService.getUpcomingReminders(userId, 24);
  }

  @Patch(':id/reminder/mark-notified')
  @ApiOperation({ summary: 'Mark reminder as notified' })
  markReminderNotified(
    @CurrentUser('sub') userId: string,
    @Param('id') noteId: string,
  ) {
    return this.calendarService.markReminderAsNotified(userId, noteId);
  }
}
