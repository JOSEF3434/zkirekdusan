// src/modules/downloads/downloads.module.ts
import { Module } from '@nestjs/common';
import { DownloadsController } from './downloads.controller.js';
import { DownloadsService } from './downloads.service.js';
import { DownloadsRepository } from './downloads.repository.js';
import { UploadsModule } from '../uploads/uploads.module.js';

@Module({
  imports: [UploadsModule],
  controllers: [DownloadsController],
  providers: [DownloadsService, DownloadsRepository],
  exports: [DownloadsService],
})
export class DownloadsModule {}
