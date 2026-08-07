import { Module } from '@nestjs/common';
import { StreamHighlightsController } from './stream-highlights.controller.js';
import { StreamHighlightsService } from './stream-highlights.service.js';
import { PrismaModule } from '../../prisma/prisma.module.js';

@Module({
  imports: [PrismaModule],
  controllers: [StreamHighlightsController],
  providers: [StreamHighlightsService],
  exports: [StreamHighlightsService],
})
export class StreamHighlightsModule {}
