import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SystemReportDisplayMode, CostCategory, CostBillingPeriod, CostType } from '@prisma/client';

export class PublicServerInfoDto {
  @ApiPropertyOptional() provider?: string;
  @ApiPropertyOptional() serviceName?: string;
  @ApiPropertyOptional() location?: string;
  @ApiPropertyOptional() region?: string;
  @ApiPropertyOptional() plan?: string;
  @ApiPropertyOptional() hostingType?: string;
  @ApiPropertyOptional() cpu?: string;
  @ApiPropertyOptional() ram?: string;
  @ApiPropertyOptional() diskCapacity?: string;
  @ApiPropertyOptional() availableStorage?: string;
  @ApiPropertyOptional() status?: string;
  @ApiPropertyOptional() health?: string;
  @ApiPropertyOptional() uptime?: string;
  @ApiPropertyOptional() maintenanceInfo?: string;
  @ApiPropertyOptional() backupConfig?: string;
  @ApiPropertyOptional() backupStorage?: string;
  @ApiPropertyOptional() monthlyCost?: number;
  @ApiPropertyOptional() yearlyCost?: number;
  @ApiPropertyOptional() currency?: string;
}

export class PublicDatabaseInfoDto {
  @ApiPropertyOptional() provider?: string;
  @ApiPropertyOptional() engine?: string;
  @ApiPropertyOptional() hostingPlan?: string;
  @ApiPropertyOptional() infrastructure?: string;
  @ApiPropertyOptional() storageUsage?: string;
  @ApiPropertyOptional() storageCapacity?: string;
  @ApiPropertyOptional() backupStatus?: string;
  @ApiPropertyOptional() health?: string;
  @ApiPropertyOptional() availability?: string;
  @ApiPropertyOptional() monthlyCost?: number;
  @ApiPropertyOptional() yearlyCost?: number;
  @ApiPropertyOptional() currency?: string;
}

export class PublicApiInfoDto {
  @ApiPropertyOptional() serviceName?: string;
  @ApiPropertyOptional() availability?: string;
  @ApiPropertyOptional() status?: string;
  @ApiPropertyOptional() responseTime?: string;
  @ApiPropertyOptional() usageStats?: string;
  @ApiPropertyOptional() hostingCost?: number;
  @ApiPropertyOptional() externalCost?: number;
  @ApiPropertyOptional() currency?: string;
}

export class PublicDeploymentInfoDto {
  @ApiPropertyOptional() provider?: string;
  @ApiPropertyOptional() environment?: string;
  @ApiPropertyOptional() appVersion?: string;
  @ApiPropertyOptional() lastDeploymentDate?: string;
  @ApiPropertyOptional() buildStatus?: string;
  @ApiPropertyOptional() deploymentCost?: number;
  @ApiPropertyOptional() currency?: string;
  @ApiPropertyOptional() environmentInfo?: string;
}

export class PublicCostItemDto {
  @ApiProperty() id!: string;
  @ApiProperty() serviceName!: string;
  @ApiProperty({ enum: CostCategory }) category!: CostCategory;
  @ApiPropertyOptional() provider?: string;
  @ApiProperty() amount!: number;
  @ApiProperty() currency!: string;
  @ApiProperty({ enum: CostBillingPeriod }) billingPeriod!: CostBillingPeriod;
  @ApiProperty({ enum: CostType }) costType!: CostType;
  @ApiPropertyOptional() description?: string;
  @ApiPropertyOptional() lastUpdatedDate?: string;
}

export class PublicSystemReportDto {
  @ApiProperty() id!: string;
  @ApiProperty() title!: string;
  @ApiPropertyOptional() summary?: string;
  @ApiPropertyOptional() notes?: string;
  @ApiProperty() revision!: number;
  @ApiProperty() publishedAt!: string;
  @ApiProperty({ enum: SystemReportDisplayMode }) displayMode!: SystemReportDisplayMode;
  @ApiPropertyOptional() server?: PublicServerInfoDto;
  @ApiPropertyOptional() database?: PublicDatabaseInfoDto;
  @ApiPropertyOptional() api?: PublicApiInfoDto;
  @ApiPropertyOptional() deployment?: PublicDeploymentInfoDto;
  @ApiProperty({ type: [PublicCostItemDto] }) costs!: PublicCostItemDto[];
  @ApiPropertyOptional({ description: 'Whether the current authenticated user has viewed/dismissed this revision' })
  hasDismissed?: boolean;
}
