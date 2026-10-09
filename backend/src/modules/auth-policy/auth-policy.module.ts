// src/modules/auth-policy/auth-policy.module.ts
import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { AuthPolicyController } from './auth-policy.controller.js';
import { AuthPolicyService } from './auth-policy.service.js';

@Module({
  imports: [PrismaModule],
  controllers: [AuthPolicyController],
  providers: [AuthPolicyService],
  exports: [AuthPolicyService],
})
export class AuthPolicyModule {}
