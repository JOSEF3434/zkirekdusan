// src/modules/profiles/dto/profile-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ProfileStatsDto {
  @ApiProperty({ example: 120 })
  followersCount!: number;

  @ApiProperty({ example: 45 })
  followingCount!: number;

  @ApiProperty({ example: 12 })
  groupsCount!: number;

  @ApiProperty({ example: 8 })
  postsCount!: number;

  @ApiProperty({ example: 3 })
  reelsCount!: number;

  @ApiProperty({ example: 3 })
  videosCount!: number;
}

export class ProfileResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  userId!: string;

  @ApiProperty({ example: 'johndoe' })
  username!: string | null;

  @ApiPropertyOptional({ example: 'John' })
  firstName?: string | null;

  @ApiPropertyOptional({ example: 'Doe' })
  lastName?: string | null;

  @ApiPropertyOptional({ example: 'John Doe' })
  displayName?: string | null;

  @ApiPropertyOptional({ example: 'Full-stack developer' })
  bio?: string | null;

  @ApiPropertyOptional({ example: 'https://johndoe.com' })
  website?: string | null;

  @ApiPropertyOptional({ example: 'United States' })
  country?: string | null;

  @ApiPropertyOptional({ example: 'PUBLIC' })
  visibility!: string;

  @ApiProperty({ example: false })
  isVerified!: boolean;

  @ApiPropertyOptional({ example: 'https://example.com/avatar.jpg' })
  avatarUrl?: string | null;

  @ApiPropertyOptional({ example: 'https://example.com/cover.jpg' })
  coverUrl?: string | null;

  @ApiProperty({ type: ProfileStatsDto })
  stats!: ProfileStatsDto;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}
