// src/modules/books/dto/update-book.dto.ts
import { PartialType } from '@nestjs/swagger';
import { CreateBookDto } from './create-book.dto.js';

export class UpdateBookDto extends PartialType(CreateBookDto) {}
