import {
  IsString,
  IsOptional,
  IsBoolean,
  IsEnum,
  IsNumber,
  IsDateString,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { CostCategory, CostBillingPeriod, CostType } from '@prisma/client';

export class CreateServiceCostDto {
  @ApiProperty()
  @IsString()
  serviceName!: string;

  @ApiPropertyOptional({ enum: CostCategory, default: CostCategory.OTHER })
  @IsOptional()
  @IsEnum(CostCategory)
  category?: CostCategory;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  provider?: string;

  @ApiProperty()
  @IsNumber()
  amount!: number;

  @ApiPropertyOptional({ default: 'USD' })
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiPropertyOptional({ enum: CostBillingPeriod, default: CostBillingPeriod.MONTHLY })
  @IsOptional()
  @IsEnum(CostBillingPeriod)
  billingPeriod?: CostBillingPeriod;

  @ApiPropertyOptional({ enum: CostType, default: CostType.ACTUAL })
  @IsOptional()
  @IsEnum(CostType)
  costType?: CostType;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  lastUpdatedDate?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isVisible?: boolean;
}

export class UpdateServiceCostDto extends PartialType(CreateServiceCostDto) {}
