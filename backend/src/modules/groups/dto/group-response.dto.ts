// src/modules/groups/dto/group-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';

export class GroupMemberSummaryDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  userId!: string;

  @ApiProperty({ example: 'johndoe' })
  username!: string | null;

  @ApiProperty({ example: 'GROUP_ADMIN' })
  role!: string;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  joinedAt!: Date;
}

export class GroupMemberResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() userId!: string;
  @ApiProperty() username!: string | null;
  @ApiPropertyOptional() displayName?: string | null;
  @ApiProperty() role!: string;
  @ApiProperty() joinedAt!: Date;
}

export class VideoChannelSummaryDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() slug!: string;
  @ApiProperty() handle!: string;
  @ApiPropertyOptional() description?: string | null;
  @ApiProperty() status!: string;
  @ApiProperty() uploadPermission!: string;
  @ApiProperty() subscribersCount!: number;
  @ApiProperty() videosCount!: number;
}

/**
 * Caller-specific capability summary derived entirely on the backend.
 * The Flutter UI uses these as display hints only.
 * Backend APIs always re-enforce authorization independently.
 */
export class GroupCapabilitiesDto {
  @ApiProperty() canViewGroup!: boolean;
  @ApiProperty() canUploadVideo!: boolean;
  @ApiProperty() canManageVideos!: boolean;
  @ApiProperty() canCreatePlaylist!: boolean;
  @ApiProperty() canManagePlaylists!: boolean;
  @ApiProperty() canViewMembers!: boolean;
  @ApiProperty() canManageMembers!: boolean;
  @ApiProperty() canEditGroup!: boolean;
  @ApiProperty() canUpdateGroup!: boolean;
  @ApiProperty() canDeleteGroup!: boolean;
  @ApiProperty() canManagePermissions!: boolean;
  @ApiProperty() canManageChannels!: boolean;
  @ApiProperty() canManageSettings!: boolean;
  @ApiProperty() canModerateChat!: boolean;
  @ApiProperty() canStartLive!: boolean;
  @ApiProperty() canApproveGroup!: boolean;
  @ApiProperty() canArchiveGroup!: boolean;
}

export class GroupContextResponseDto {
  // ---- Group identity ----
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() slug!: string;
  @ApiPropertyOptional() description?: string | null;
  @ApiProperty() status!: string;
  @ApiProperty() visibility!: string;
  @ApiProperty() membersCount!: number;
  @ApiPropertyOptional() avatarUrl?: string | null;
  @ApiPropertyOptional() coverUrl?: string | null;
  @ApiPropertyOptional() website?: string | null;
  @ApiPropertyOptional() country?: string | null;
  @ApiProperty() createdById!: string;
  @ApiPropertyOptional() approvedById?: string | null;
  @ApiPropertyOptional() approvedAt?: Date | null;
  @ApiProperty() createdAt!: Date;

  // ---- Caller membership ----
  /** null = not a member (or unauthenticated) */
  @ApiPropertyOptional({ nullable: true })
  callerRole?: string | null;

  @ApiProperty({ type: GroupCapabilitiesDto })
  capabilities!: GroupCapabilitiesDto;

  // ---- Video channels ----
  @ApiProperty({ type: [VideoChannelSummaryDto] })
  videoChannels!: VideoChannelSummaryDto[];

  /**
   * Deterministic primary channel ID:
   * - If there is exactly one ACTIVE channel → its ID
   * - If there are multiple → the one created first (oldest) is considered primary
   * - If there are none → null
   */
  @ApiPropertyOptional({ nullable: true })
  defaultVideoChannelId?: string | null;
}

export class GroupResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: 'Tech Enthusiasts' })
  name!: string;

  @ApiProperty({ example: 'tech-enthusiasts' })
  slug!: string;

  @ApiPropertyOptional({
    example: 'A community for technology and software discussions',
  })
  description?: string | null;

  @ApiProperty({ example: 'PENDING_APPROVAL' })
  status!: string;

  @ApiProperty({ example: 'PUBLIC' })
  visibility!: string;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  createdById!: string;

  @ApiPropertyOptional({ example: '123e4567-e89b-12d3-a456-426614174000' })
  approvedById?: string | null;

  @ApiPropertyOptional({ example: '2024-01-15T10:00:00.000Z' })
  approvedAt?: Date | null;

  @ApiProperty({ example: 42 })
  membersCount!: number;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}
