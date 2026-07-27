// src/common/dto/api-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PaginationMeta {
  @ApiProperty({ example: 1 })
  page!: number;

  @ApiProperty({ example: 20 })
  limit!: number;

  @ApiProperty({ example: 100 })
  total!: number;

  @ApiProperty({ example: 5 })
  totalPages!: number;

  @ApiProperty({ example: true })
  hasNext!: boolean;

  @ApiProperty({ example: false })
  hasPrev!: boolean;
}

export class ApiResponse<T = unknown> {
  @ApiProperty({ example: true })
  success!: boolean;

  @ApiPropertyOptional()
  data?: T;

  @ApiPropertyOptional({ example: 'Operation completed successfully' })
  message?: string;

  @ApiPropertyOptional({ type: PaginationMeta })
  meta?: PaginationMeta;

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  timestamp!: string;

  constructor(partial?: Partial<ApiResponse<T>>) {
    if (partial) {
      Object.assign(this, partial);
    }
    this.timestamp = new Date().toISOString();
  }
}

export class ApiErrorResponse {
  @ApiProperty({ example: false })
  success!: boolean;

  @ApiProperty({ example: 'Bad Request' })
  error!: string;

  @ApiProperty({ example: 400 })
  statusCode!: number;

  @ApiPropertyOptional({ example: ['email must be a valid email'] })
  details?: string | string[];

  @ApiProperty({ example: '2024-01-15T10:00:00.000Z' })
  timestamp!: string;

  @ApiProperty({ example: '/api/auth/login' })
  path!: string;
}
