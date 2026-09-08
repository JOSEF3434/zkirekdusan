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
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Calendar')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('calendar/notes')
export class CalendarController {
  constructor(private readonly calendarService: CalendarService) {}

  @Post()
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
    @CurrentUser('sub') userId: string,
    @Query() query: QueryCalendarNotesDto,
  ) {
    return this.calendarService.findAll(userId, query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific calendar note' })
  findOne(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    return this.calendarService.findOne(userId, id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a calendar note' })
  update(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() updateDto: UpdateCalendarNoteDto,
  ) {
    return this.calendarService.update(userId, id, updateDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a calendar note (soft delete)' })
  remove(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    return this.calendarService.remove(userId, id);
  }
}
