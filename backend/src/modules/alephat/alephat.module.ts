// src/modules/alephat/alephat.module.ts
import { Module } from '@nestjs/common';
import { AlephatService } from './alephat.service.js';
import { AlephatController } from './alephat.controller.js';
import { PrismaModule } from '../../prisma/prisma.module.js';

@Module({
  imports: [PrismaModule],
  controllers: [AlephatController],
  providers: [AlephatService],
  exports: [AlephatService],
})
export class AlephatModule {}
