import { PartialType } from '@nestjs/swagger';
import { CreateCalendarNoteDto } from './create-calendar-note.dto.js';

export class UpdateCalendarNoteDto extends PartialType(CreateCalendarNoteDto) {}
