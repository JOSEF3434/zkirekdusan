// src/modules/groups/dto/group-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

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
