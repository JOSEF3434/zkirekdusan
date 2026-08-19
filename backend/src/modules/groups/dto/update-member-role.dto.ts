// src/modules/groups/dto/update-member-role.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';
import { GroupRole } from '../../../common/constants/group-roles.js';

export class UpdateMemberRoleDto {
  @ApiProperty({ enum: GroupRole, example: GroupRole.MODERATOR })
  @IsEnum(GroupRole)
  role!: GroupRole;
}
