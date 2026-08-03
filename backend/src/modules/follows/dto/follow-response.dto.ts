// src/modules/follows/dto/follow-response.dto.ts
import { ApiProperty } from '@nestjs/swagger';

export class FollowUserSummaryDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id!: string;

  @ApiProperty({ example: 'johndoe' })
  username!: string | null;

  @ApiProperty({ example: 'John Doe', nullable: true })
  displayName?: string | null;

  @ApiProperty({
    example: 'https://cdn.example.com/avatar.jpg',
    nullable: true,
  })
  avatarUrl?: string | null;
}

export class FollowResponseDto {
  @ApiProperty({ type: FollowUserSummaryDto })
  user!: FollowUserSummaryDto;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  createdAt!: Date;
}

export class FollowStatusDto {
  @ApiProperty({ example: true })
  isFollowing!: boolean;

  @ApiProperty({ example: false })
  isFollowedBy!: boolean;
}
