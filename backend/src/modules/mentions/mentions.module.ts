// src/modules/mentions/mentions.module.ts
import { Module } from '@nestjs/common';
import { MentionsController } from './mentions.controller.js';
import { MentionsService } from './mentions.service.js';
import { MentionsRepository } from './mentions.repository.js';
import { PrismaModule } from '../../prisma/prisma.module.js';

@Module({
  imports: [PrismaModule],
  controllers: [MentionsController],
  providers: [MentionsService, MentionsRepository],
  exports: [MentionsService],
})
export class MentionsModule {}
