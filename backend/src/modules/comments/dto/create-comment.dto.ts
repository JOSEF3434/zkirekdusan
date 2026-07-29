// src/modules/comments/dto/create-comment.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateCommentDto {
  @ApiProperty({ example: 'This is a comment content' })
  @IsString()
  @IsNotEmpty({ message: 'Comment content cannot be empty' })
  content!: string;

  @ApiPropertyOptional({ example: 'parent-comment-uuid', description: 'Pass parentId if this is a reply to an existing comment' })
  @IsOptional()
  @IsUUID()
  parentId?: string;
}
