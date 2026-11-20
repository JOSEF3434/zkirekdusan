import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { CalendarEventsService } from './calendar-events.service.js';
import { CreateCalendarEventDto } from './dto/create-calendar-event.dto.js';
import { UpdateCalendarEventDto } from './dto/update-calendar-event.dto.js';
import { QueryCalendarEventsDto } from './dto/query-calendar-events.dto.js';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { PermissionsGuard } from '../../common/guards/permissions.guard.js';
import { Permissions } from '../../common/decorators/permissions.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { PERMISSIONS } from '../../common/constants/permissions.js';

@ApiTags('Calendar Events — Fasting & Holidays')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Controller('calendar/events')
export class CalendarEventsController {
  constructor(private readonly eventsService: CalendarEventsService) {}

  @Get('month')
  @Permissions(PERMISSIONS.CALENDAR.VIEW)
  @ApiOperation({ summary: 'Get fasting periods and holidays overlapping an Ethiopian month' })
  getEventsForMonth(
    @Query('year', ParseIntPipe) year: number,
    @Query('month', ParseIntPipe) month: number,
  ) {
    return this.eventsService.getEventsForMonth(year, month);
  }

  @Get('year')
  @Permissions(PERMISSIONS.CALENDAR.VIEW)
  @ApiOperation({ summary: 'Get all fasting periods and holidays for an Ethiopian year' })
  getEventsForYear(@Query('year', ParseIntPipe) year: number) {
    return this.eventsService.getEventsForYear(year);
  }

  @Get('day')
  @Permissions(PERMISSIONS.CALENDAR.VIEW)
  @ApiOperation({ summary: 'Get fasting and holiday events on a specific Ethiopian date' })
  getEventsForDay(
    @Query('year', ParseIntPipe) year: number,
    @Query('month', ParseIntPipe) month: number,
    @Query('day', ParseIntPipe) day: number,
  ) {
    return this.eventsService.getEventsForDay(year, month, day);
  }

  @Get()
  @Permissions(PERMISSIONS.CALENDAR.VIEW)
  @ApiOperation({ summary: 'List calendar fasting periods and holidays with optional filters' })
  findAll(@Query() query: QueryCalendarEventsDto) {
    return this.eventsService.findAll(query);
  }

  @Get(':id')
  @Permissions(PERMISSIONS.CALENDAR.VIEW)
  @ApiOperation({ summary: 'Get details of a specific calendar event' })
  findOne(@Param('id') id: string) {
    return this.eventsService.findOne(id);
  }

  @Post()
  @Permissions(PERMISSIONS.CALENDAR.CREATE)
  @ApiOperation({ summary: 'Create a new fasting period or holiday (Admin only)' })
  create(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateCalendarEventDto,
  ) {
    return this.eventsService.create(userId, dto);
  }

  @Patch(':id')
  @Permissions(PERMISSIONS.CALENDAR.UPDATE)
  @ApiOperation({ summary: 'Update an existing fasting period or holiday (Admin only)' })
  update(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateCalendarEventDto,
  ) {
    return this.eventsService.update(userId, id, dto);
  }

  @Patch(':id/toggle-status')
  @Permissions(PERMISSIONS.CALENDAR.UPDATE)
  @ApiOperation({ summary: 'Toggle active/inactive status of an event (Admin only)' })
  toggleStatus(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
  ) {
    return this.eventsService.toggleStatus(userId, id);
  }

  @Delete(':id')
  @Permissions(PERMISSIONS.CALENDAR.DELETE)
  @ApiOperation({ summary: 'Soft delete a calendar event (Admin only)' })
  remove(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
  ) {
    return this.eventsService.remove(userId, id);
  }
}
