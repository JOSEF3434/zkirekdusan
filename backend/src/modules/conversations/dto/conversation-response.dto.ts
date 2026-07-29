// src/modules/conversations/dto/conversation-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ConversationType } from '@prisma/client';

export class ConversationMemberDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  userId!: string;

  @ApiProperty({ example: 'johndoe' })
  username!: string;

  @ApiPropertyOptional({ example: 'John Doe', nullable: true })
  displayName?: string | null;

  @ApiPropertyOptional({ example: 'https://cdn.example.com/avatar.jpg', nullable: true })
  avatarUrl?: string | null;

  @ApiProperty({ example: 0 })
  unreadCount!: number;

  @ApiProperty({ example: false })
  isMuted!: boolean;
}

export class ConversationResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ enum: ConversationType })
  type!: ConversationType;

  @ApiPropertyOptional({ example: 'group-uuid', nullable: true })
  groupId?: string | null;

  @ApiPropertyOptional({ example: 'channel-uuid', nullable: true })
  channelId?: string | null;

  @ApiPropertyOptional({ example: 'Channel Name', nullable: true })
  title?: string | null;

  @ApiPropertyOptional({ example: 'Last message snippet...', nullable: true })
  lastMessageSnippet?: string | null;

  @ApiPropertyOptional({ example: '2024-01-15T10:00:00.000Z', nullable: true })
  lastMessageAt?: Date | null;

  @ApiProperty({ type: [ConversationMemberDto] })
  members!: ConversationMemberDto[];

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}
