// src/modules/presence/presence.module.ts
import { Module } from '@nestjs/common';
import { PresenceController } from './presence.controller.js';
import { PresenceService } from './presence.service.js';
import { PresenceRepository } from './presence.repository.js';

@Module({
  controllers: [PresenceController],
  providers: [PresenceService, PresenceRepository],
  exports: [PresenceService],
})
export class PresenceModule {}
