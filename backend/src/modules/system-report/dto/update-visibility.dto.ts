import { IsBoolean, IsEnum, IsOptional } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { SystemReportDisplayMode } from '@prisma/client';

export class UpdateVisibilityDto {
  // Global Switch
  @ApiPropertyOptional({ description: 'Global toggle. When false, ordinary users see nothing.' })
  @IsOptional()
  @IsBoolean()
  enableUserVisibility?: boolean;

  @ApiPropertyOptional({ enum: SystemReportDisplayMode })
  @IsOptional()
  @IsEnum(SystemReportDisplayMode)
  displayMode?: SystemReportDisplayMode;

  // Category switches
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayServerInfo?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayServerCosts?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayDatabaseInfo?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayDatabaseCosts?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayApiInfo?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayApiCosts?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayDeploymentInfo?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayDeploymentCosts?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayStorageInfo?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayBackupInfo?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayMaintenanceInfo?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayUptimeInfo?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  displayAdditionalCosts?: boolean;

  // Individual Server fields
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerProvider?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerServiceName?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerLocation?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerRegion?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerPlan?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerHostingType?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerCpu?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerRam?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerDiskCapacity?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerAvailableStorage?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerStatus?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerHealth?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerUptime?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerMaintenanceInfo?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerBackupConfig?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerBackupStorage?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerMonthlyCost?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showServerYearlyCost?: boolean;

  // Individual Database fields
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDbProvider?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDbEngine?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDbHostingPlan?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDbInfrastructure?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDbStorageUsage?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDbStorageCapacity?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDbBackupStatus?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDbHealth?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDbAvailability?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDbMonthlyCost?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDbYearlyCost?: boolean;

  // Individual API fields
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showApiServiceName?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showApiAvailability?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showApiStatus?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showApiResponseTime?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showApiUsageStats?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showApiHostingCost?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showApiExternalCost?: boolean;

  // Individual Deployment fields
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDeploymentProvider?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDeploymentEnvironment?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showAppVersion?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showLastDeploymentDate?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showBuildStatus?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showDeploymentCost?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showEnvironmentInfo?: boolean;
}
