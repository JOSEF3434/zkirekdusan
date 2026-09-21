import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum ReportReasonEnum {
  SPAM = 'SPAM',
  HARASSMENT = 'HARASSMENT',
  HATE_SPEECH = 'HATE_SPEECH',
  MISINFORMATION = 'MISINFORMATION',
  INAPPROPRIATE_CONTENT = 'INAPPROPRIATE_CONTENT',
  VIOLENCE = 'VIOLENCE',
  COPYRIGHT = 'COPYRIGHT',
  IMPERSONATION = 'IMPERSONATION',
  OTHER = 'OTHER',
}

export enum ReportTargetTypeEnum {
  USER = 'USER',
  GROUP = 'GROUP',
  POST = 'POST',
  COMMENT = 'COMMENT',
  VIDEO = 'VIDEO',
  MESSAGE = 'MESSAGE',
}

export class CreateReportDto {
  @ApiProperty({
    enum: ReportTargetTypeEnum,
    description: 'Type of entity being reported',
    example: 'USER',
  })
  @IsEnum(ReportTargetTypeEnum)
  @IsNotEmpty()
  targetType!: ReportTargetTypeEnum;

  @ApiProperty({
    description: 'Identifier of the entity (user ID/group ID/post ID)',
    example: 'uuid-or-id',
  })
  @IsString()
  @IsNotEmpty()
  targetId!: string;

  @ApiPropertyOptional({
    description:
      'Associated target user ID (e.g. author or user being reported)',
  })
  @IsString()
  @IsOptional()
  targetUserId?: string;

  @ApiProperty({
    enum: ReportReasonEnum,
    description: 'Reason for reporting',
    example: 'SPAM',
  })
  @IsEnum(ReportReasonEnum)
  @IsNotEmpty()
  reason!: ReportReasonEnum;

  @ApiPropertyOptional({
    description: 'Optional additional explanation/comment from the reporter',
    maxLength: 1000,
  })
  @IsString()
  @IsOptional()
  @MaxLength(1000)
  comment?: string;
}
