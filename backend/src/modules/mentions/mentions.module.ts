// src/modules/mentions/mentions.module.ts
import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { SearchModule } from '../search/search.module.js';
import { MentionsController } from './mentions.controller.js';
import { MentionsService } from './mentions.service.js';
import { MentionsRepository } from './mentions.repository.js';

@Module({
  imports: [PrismaModule, SearchModule],
  controllers: [MentionsController],
  providers: [MentionsService, MentionsRepository],
  exports: [MentionsService, MentionsRepository],
})
export class MentionsModule {}
