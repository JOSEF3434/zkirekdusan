// src/common/common.module.ts
import { Module, Global } from '@nestjs/common';
import { PasswordService } from './service/password.service.js';
import { GroupMembershipGuard } from './guards/group-membership.guard.js';

@Global()
@Module({
  providers: [PasswordService, GroupMembershipGuard],
  exports: [PasswordService, GroupMembershipGuard],
})
export class CommonModule {}
