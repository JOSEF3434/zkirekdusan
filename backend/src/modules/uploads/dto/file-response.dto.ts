// src/modules/uploads/dto/file-response.dto.ts
import { ApiProperty } from '@nestjs/swagger';

export class FileResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: 'photo.jpg' })
  originalName!: string;

  @ApiProperty({ example: 'image/jpeg' })
  mimeType!: string;

  @ApiProperty({ example: 1024500 })
  size!: number;

  @ApiProperty({ example: 'IMAGE' })
  fileType!: string;

  @ApiProperty({ example: 'LOCAL' })
  provider!: string;

  @ApiProperty({ example: 'http://localhost:3000/uploads/groups/photo.jpg' })
  url!: string;

  @ApiProperty({ example: 'READY' })
  status!: string;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  uploadedById!: string;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000', nullable: true })
  groupId?: string | null;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}
