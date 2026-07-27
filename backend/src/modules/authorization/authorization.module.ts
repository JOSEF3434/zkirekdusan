import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { AuthorizationService } from './authorization.service.js';

@Module({
  imports: [PrismaModule],
  exports: [AuthorizationService],
  providers: [AuthorizationService],
})
export class AuthorizationModule {}
