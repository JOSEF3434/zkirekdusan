// src/modules/messages/dto/message-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class MessageSenderDto {
  @ApiProperty() id!: string;
  @ApiProperty() username!: string | null;
  @ApiPropertyOptional() displayName?: string;
  @ApiPropertyOptional() avatarUrl?: string;
}

export class MessageAttachmentResponseDto {
  @ApiProperty() fileId!: string;
  @ApiProperty() url!: string;
  @ApiProperty() fileType!: string;
  @ApiProperty() mimeType!: string;
  @ApiProperty() originalName!: string;
  @ApiPropertyOptional() size?: number;
  @ApiPropertyOptional() width?: number;
  @ApiPropertyOptional() height?: number;
  @ApiPropertyOptional() duration?: number;
  @ApiPropertyOptional() thumbnailUrl?: string;
}

export class MessageReactionResponseDto {
  @ApiProperty() emoji!: string;
  @ApiProperty() count!: number;
  @ApiProperty({ type: [String] }) userIds!: string[];
}

export class VoiceMessageResponseDto {
  @ApiProperty() duration!: number;
  @ApiPropertyOptional() waveform?: number[];
  @ApiProperty() url!: string;
}

export class ForwardInfoDto {
  @ApiProperty() originalMessageId!: string;
  @ApiProperty() originalSenderId!: string;
  @ApiPropertyOptional() originalSenderName?: string;
  @ApiPropertyOptional() originalSenderAvatar?: string;
}

export class MessageResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() conversationId!: string;
  @ApiPropertyOptional() channelId?: string;
  @ApiProperty({ type: MessageSenderDto }) sender!: MessageSenderDto;
  @ApiPropertyOptional() content?: string;
  @ApiProperty() type!: string;
  @ApiPropertyOptional() replyToId?: string;
  @ApiPropertyOptional() replyTo?: {
    id: string;
    content?: string;
    type: string;
    sender: MessageSenderDto;
    attachments?: MessageAttachmentResponseDto[];
  };
  @ApiProperty() isEdited!: boolean;
  @ApiProperty() isPinned!: boolean;
  @ApiPropertyOptional() isDeleted?: boolean;
  @ApiProperty({ type: [MessageAttachmentResponseDto] })
  attachments!: MessageAttachmentResponseDto[];
  @ApiProperty({ type: [MessageReactionResponseDto] })
  reactions!: MessageReactionResponseDto[];
  @ApiProperty({ type: [String] }) readBy!: string[];
  @ApiProperty({ type: [String] }) deliveredTo!: string[];
  @ApiPropertyOptional({ type: VoiceMessageResponseDto })
  voiceNote?: VoiceMessageResponseDto;
  @ApiPropertyOptional({ type: ForwardInfoDto }) forwardInfo?: ForwardInfoDto;
  @ApiPropertyOptional({ type: [String] }) mentionedUserIds?: string[];
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;
}

export class PaginatedMessagesDto {
  @ApiProperty({ type: [MessageResponseDto] }) data!: MessageResponseDto[];
  @ApiPropertyOptional() nextCursor?: string;
  @ApiProperty() hasMore!: boolean;
  @ApiProperty() total?: number;
}
