// src/modules/books/books.module.ts
import { Module } from '@nestjs/common';
import { BooksService } from './books.service.js';
import {
  BooksPublicController,
  BooksUserController,
  BooksAdminController,
} from './books.controller.js';
import { PrismaModule } from '../../prisma/prisma.module.js';

@Module({
  imports: [PrismaModule],
  controllers: [BooksPublicController, BooksUserController, BooksAdminController],
  providers: [BooksService],
  exports: [BooksService],
})
export class BooksModule {}
