// src/modules/notifications/dto/notification-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class NotificationResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() type!: string;
  @ApiProperty() title!: string;
  @ApiProperty() body!: string;
  @ApiPropertyOptional() data?: Record<string, any>;
  @ApiProperty() isRead!: boolean;
  @ApiProperty() createdAt!: Date;
}
