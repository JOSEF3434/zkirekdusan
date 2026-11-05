// src/modules/books/books.module.ts
import { Module } from '@nestjs/common';
import { BooksService } from './books.service.js';
import {
  BooksPublicController,
  BooksUserController,
  BooksAdminController,
} from './books.controller.js';
import {
  DictionaryAdminController,
  DictionaryUserController,
} from './dictionary/dictionary.controller.js';
import { DictionaryService } from './dictionary/dictionary.service.js';
import { DictionaryParserService } from './dictionary/dictionary-parser.service.js';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { UploadsModule } from '../uploads/uploads.module.js';

@Module({
  imports: [PrismaModule, UploadsModule],
  controllers: [
    BooksPublicController,
    BooksUserController,
    BooksAdminController,
    DictionaryAdminController,
    DictionaryUserController,
  ],
  providers: [BooksService, DictionaryService, DictionaryParserService],
  exports: [BooksService, DictionaryService, DictionaryParserService],
})
export class BooksModule {}
