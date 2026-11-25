import {
  IsString,
  IsOptional,
  IsBoolean,
  IsEnum,
  IsNumber,
  IsDateString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  SystemReportStatus,
  SystemReportDisplayMode,
  CostCategory,
  CostBillingPeriod,
  CostType,
} from '@prisma/client';

export class ServiceCostItemDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty()
  @IsString()
  serviceName!: string;

  @ApiPropertyOptional({ enum: CostCategory })
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

export class CreateSystemReportDto {
  @ApiPropertyOptional({ default: 'System Infrastructure & Operations Report' })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  summary?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ enum: SystemReportDisplayMode, default: SystemReportDisplayMode.SETTINGS_ONLY })
  @IsOptional()
  @IsEnum(SystemReportDisplayMode)
  displayMode?: SystemReportDisplayMode;

  // Server
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverProvider?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverServiceName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverLocation?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverRegion?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverPlan?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverHostingType?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverCpu?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverRam?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverDiskCapacity?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverAvailableStorage?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverStatus?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverHealth?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverUptime?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverMaintenanceInfo?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverBackupConfig?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverBackupStorage?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  serverMonthlyCost?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  serverYearlyCost?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  serverCostCurrency?: string;

  // Database
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dbProvider?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dbEngine?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dbHostingPlan?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dbInfrastructure?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dbStorageUsage?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dbStorageCapacity?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dbBackupStatus?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dbHealth?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dbAvailability?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  dbMonthlyCost?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  dbYearlyCost?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dbCostCurrency?: string;

  // API
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  apiServiceName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  apiAvailability?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  apiStatus?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  apiResponseTime?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  apiUsageStats?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  apiHostingCost?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  apiExternalCost?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  apiCostCurrency?: string;

  // Deployment
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  deploymentProvider?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  deploymentEnvironment?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  appVersion?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  lastDeploymentDate?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  buildStatus?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  deploymentCost?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  deploymentCostCurrency?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  environmentInfo?: string;

  @ApiPropertyOptional({ type: [ServiceCostItemDto] })
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => ServiceCostItemDto)
  costs?: ServiceCostItemDto[];
}
