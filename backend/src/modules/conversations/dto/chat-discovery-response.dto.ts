// src/modules/conversations/dto/chat-discovery-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ConversationResponseDto } from './conversation-response.dto.js';

export class ChatUserItemDto {
  @ApiProperty()
  id!: string;

  @ApiPropertyOptional()
  username?: string | null;

  @ApiPropertyOptional()
  displayName?: string | null;

  @ApiPropertyOptional()
  avatarUrl?: string | null;

  @ApiPropertyOptional()
  bio?: string | null;

  @ApiProperty()
  isOnline!: boolean;

  @ApiPropertyOptional()
  lastSeenAt?: Date | null;

  @ApiProperty()
  createdAt!: Date;
}

export class ChatGroupItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty()
  slug!: string;

  @ApiPropertyOptional()
  description?: string | null;

  @ApiPropertyOptional()
  avatarUrl?: string | null;

  @ApiPropertyOptional()
  coverUrl?: string | null;

  @ApiProperty()
  visibility!: string;

  @ApiProperty()
  status!: string;

  @ApiProperty()
  membersCount!: number;

  @ApiPropertyOptional()
  conversationId?: string | null;

  @ApiProperty()
  isMember!: boolean;

  @ApiProperty()
  createdAt!: Date;
}

export class ChatDiscoveryResponseDto {
  @ApiProperty({ type: [ConversationResponseDto] })
  conversations!: ConversationResponseDto[];

  @ApiProperty({ type: [ChatGroupItemDto] })
  publicGroups!: ChatGroupItemDto[];

  @ApiProperty({ type: [ChatGroupItemDto] })
  myPrivateGroups!: ChatGroupItemDto[];

  @ApiProperty({ type: [ChatUserItemDto] })
  allUsers!: ChatUserItemDto[];
}
