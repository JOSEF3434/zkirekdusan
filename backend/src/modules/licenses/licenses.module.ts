// src/modules/licenses/licenses.module.ts
import { Module } from '@nestjs/common';
import { LicensesController } from './licenses.controller.js';
import { LicensesService } from './licenses.service.js';

@Module({
  controllers: [LicensesController],
  providers: [LicensesService],
  exports: [LicensesService],
})
export class LicensesModule {}
