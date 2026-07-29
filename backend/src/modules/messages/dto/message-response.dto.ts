// src/modules/messages/dto/message-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class MessageSenderDto {
  @ApiProperty() id!: string;
  @ApiProperty() username!: string;
  @ApiPropertyOptional() displayName?: string;
  @ApiPropertyOptional() avatarUrl?: string;
}

export class MessageAttachmentResponseDto {
  @ApiProperty() fileId!: string;
  @ApiProperty() url!: string;
  @ApiProperty() fileType!: string;
  @ApiProperty() mimeType!: string;
  @ApiProperty() originalName!: string;
}

export class MessageReactionResponseDto {
  @ApiProperty() emoji!: string;
  @ApiProperty() count!: number;
  @ApiProperty({ type: [String] }) userIds!: string[];
}

export class MessageResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() conversationId!: string;
  @ApiPropertyOptional() channelId?: string;
  @ApiProperty({ type: MessageSenderDto }) sender!: MessageSenderDto;
  @ApiPropertyOptional() content?: string;
  @ApiProperty() type!: string;
  @ApiPropertyOptional() replyToId?: string;
  @ApiPropertyOptional() replyTo?: Pick<MessageResponseDto, 'id' | 'content' | 'sender'>;
  @ApiProperty() isEdited!: boolean;
  @ApiProperty() isPinned!: boolean;
  @ApiProperty({ type: [MessageAttachmentResponseDto] }) attachments!: MessageAttachmentResponseDto[];
  @ApiProperty({ type: [MessageReactionResponseDto] }) reactions!: MessageReactionResponseDto[];
  @ApiProperty({ type: [String] }) readBy!: string[];
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;
}

export class PaginatedMessagesDto {
  @ApiProperty({ type: [MessageResponseDto] }) data!: MessageResponseDto[];
  @ApiPropertyOptional() nextCursor?: string;
  @ApiProperty() hasMore!: boolean;
}
