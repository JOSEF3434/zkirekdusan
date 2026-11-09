// src/modules/well-known/well-known.module.ts
import { Module } from '@nestjs/common';
import { WellKnownController } from './well-known.controller.js';

@Module({
  controllers: [WellKnownController],
})
export class WellKnownModule {}
