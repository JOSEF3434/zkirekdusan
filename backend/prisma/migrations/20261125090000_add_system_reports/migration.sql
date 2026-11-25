-- CreateEnum
CREATE TYPE "SystemReportStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'UNPUBLISHED');

-- CreateEnum
CREATE TYPE "SystemReportDisplayMode" AS ENUM ('SETTINGS_ONLY', 'POPUP_ONLY', 'BOTH');

-- CreateEnum
CREATE TYPE "CostCategory" AS ENUM ('SERVER_HOSTING', 'DATABASE', 'API_SERVICES', 'STORAGE_CDN', 'BANDWIDTH', 'EMAIL', 'SMS', 'PUSH_NOTIFICATIONS', 'BACKUP', 'MONITORING', 'OTHER');

-- CreateEnum
CREATE TYPE "CostBillingPeriod" AS ENUM ('MONTHLY', 'YEARLY', 'ONE_TIME');

-- CreateEnum
CREATE TYPE "CostType" AS ENUM ('ACTUAL', 'ESTIMATED');

-- CreateTable
CREATE TABLE IF NOT EXISTS "system_reports" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL DEFAULT 'System Infrastructure & Operations Report',
    "summary" TEXT,
    "notes" TEXT,
    "status" "SystemReportStatus" NOT NULL DEFAULT 'DRAFT',
    "revision" INTEGER NOT NULL DEFAULT 1,
    "publishedAt" TIMESTAMP(3),
    "unpublishedAt" TIMESTAMP(3),
    "createdById" TEXT,
    "updatedById" TEXT,
    "enableUserVisibility" BOOLEAN NOT NULL DEFAULT false,
    "displayMode" "SystemReportDisplayMode" NOT NULL DEFAULT 'SETTINGS_ONLY',
    "displayServerInfo" BOOLEAN NOT NULL DEFAULT false,
    "displayServerCosts" BOOLEAN NOT NULL DEFAULT false,
    "displayDatabaseInfo" BOOLEAN NOT NULL DEFAULT false,
    "displayDatabaseCosts" BOOLEAN NOT NULL DEFAULT false,
    "displayApiInfo" BOOLEAN NOT NULL DEFAULT false,
    "displayApiCosts" BOOLEAN NOT NULL DEFAULT false,
    "displayDeploymentInfo" BOOLEAN NOT NULL DEFAULT false,
    "displayDeploymentCosts" BOOLEAN NOT NULL DEFAULT false,
    "displayStorageInfo" BOOLEAN NOT NULL DEFAULT false,
    "displayBackupInfo" BOOLEAN NOT NULL DEFAULT false,
    "displayMaintenanceInfo" BOOLEAN NOT NULL DEFAULT false,
    "displayUptimeInfo" BOOLEAN NOT NULL DEFAULT false,
    "displayAdditionalCosts" BOOLEAN NOT NULL DEFAULT false,
    "serverProvider" TEXT,
    "serverServiceName" TEXT,
    "serverLocation" TEXT,
    "serverRegion" TEXT,
    "serverPlan" TEXT,
    "serverHostingType" TEXT,
    "serverCpu" TEXT,
    "serverRam" TEXT,
    "serverDiskCapacity" TEXT,
    "serverAvailableStorage" TEXT,
    "serverStatus" TEXT,
    "serverHealth" TEXT,
    "serverUptime" TEXT,
    "serverMaintenanceInfo" TEXT,
    "serverBackupConfig" TEXT,
    "serverBackupStorage" TEXT,
    "serverMonthlyCost" DECIMAL(10,2),
    "serverYearlyCost" DECIMAL(10,2),
    "serverCostCurrency" TEXT NOT NULL DEFAULT 'USD',
    "showServerProvider" BOOLEAN NOT NULL DEFAULT false,
    "showServerServiceName" BOOLEAN NOT NULL DEFAULT false,
    "showServerLocation" BOOLEAN NOT NULL DEFAULT false,
    "showServerRegion" BOOLEAN NOT NULL DEFAULT false,
    "showServerPlan" BOOLEAN NOT NULL DEFAULT false,
    "showServerHostingType" BOOLEAN NOT NULL DEFAULT false,
    "showServerCpu" BOOLEAN NOT NULL DEFAULT false,
    "showServerRam" BOOLEAN NOT NULL DEFAULT false,
    "showServerDiskCapacity" BOOLEAN NOT NULL DEFAULT false,
    "showServerAvailableStorage" BOOLEAN NOT NULL DEFAULT false,
    "showServerStatus" BOOLEAN NOT NULL DEFAULT false,
    "showServerHealth" BOOLEAN NOT NULL DEFAULT false,
    "showServerUptime" BOOLEAN NOT NULL DEFAULT false,
    "showServerMaintenanceInfo" BOOLEAN NOT NULL DEFAULT false,
    "showServerBackupConfig" BOOLEAN NOT NULL DEFAULT false,
    "showServerBackupStorage" BOOLEAN NOT NULL DEFAULT false,
    "showServerMonthlyCost" BOOLEAN NOT NULL DEFAULT false,
    "showServerYearlyCost" BOOLEAN NOT NULL DEFAULT false,
    "dbProvider" TEXT,
    "dbEngine" TEXT,
    "dbHostingPlan" TEXT,
    "dbInfrastructure" TEXT,
    "dbStorageUsage" TEXT,
    "dbStorageCapacity" TEXT,
    "dbBackupStatus" TEXT,
    "dbHealth" TEXT,
    "dbAvailability" TEXT,
    "dbMonthlyCost" DECIMAL(10,2),
    "dbYearlyCost" DECIMAL(10,2),
    "dbCostCurrency" TEXT NOT NULL DEFAULT 'USD',
    "showDbProvider" BOOLEAN NOT NULL DEFAULT false,
    "showDbEngine" BOOLEAN NOT NULL DEFAULT false,
    "showDbHostingPlan" BOOLEAN NOT NULL DEFAULT false,
    "showDbInfrastructure" BOOLEAN NOT NULL DEFAULT false,
    "showDbStorageUsage" BOOLEAN NOT NULL DEFAULT false,
    "showDbStorageCapacity" BOOLEAN NOT NULL DEFAULT false,
    "showDbBackupStatus" BOOLEAN NOT NULL DEFAULT false,
    "showDbHealth" BOOLEAN NOT NULL DEFAULT false,
    "showDbAvailability" BOOLEAN NOT NULL DEFAULT false,
    "showDbMonthlyCost" BOOLEAN NOT NULL DEFAULT false,
    "showDbYearlyCost" BOOLEAN NOT NULL DEFAULT false,
    "apiServiceName" TEXT,
    "apiAvailability" TEXT,
    "apiStatus" TEXT,
    "apiResponseTime" TEXT,
    "apiUsageStats" TEXT,
    "apiHostingCost" DECIMAL(10,2),
    "apiExternalCost" DECIMAL(10,2),
    "apiCostCurrency" TEXT NOT NULL DEFAULT 'USD',
    "showApiServiceName" BOOLEAN NOT NULL DEFAULT false,
    "showApiAvailability" BOOLEAN NOT NULL DEFAULT false,
    "showApiStatus" BOOLEAN NOT NULL DEFAULT false,
    "showApiResponseTime" BOOLEAN NOT NULL DEFAULT false,
    "showApiUsageStats" BOOLEAN NOT NULL DEFAULT false,
    "showApiHostingCost" BOOLEAN NOT NULL DEFAULT false,
    "showApiExternalCost" BOOLEAN NOT NULL DEFAULT false,
    "deploymentProvider" TEXT,
    "deploymentEnvironment" TEXT,
    "appVersion" TEXT,
    "lastDeploymentDate" TIMESTAMP(3),
    "buildStatus" TEXT,
    "deploymentCost" DECIMAL(10,2),
    "deploymentCostCurrency" TEXT NOT NULL DEFAULT 'USD',
    "environmentInfo" TEXT,
    "showDeploymentProvider" BOOLEAN NOT NULL DEFAULT false,
    "showDeploymentEnvironment" BOOLEAN NOT NULL DEFAULT false,
    "showAppVersion" BOOLEAN NOT NULL DEFAULT false,
    "showLastDeploymentDate" BOOLEAN NOT NULL DEFAULT false,
    "showBuildStatus" BOOLEAN NOT NULL DEFAULT false,
    "showDeploymentCost" BOOLEAN NOT NULL DEFAULT false,
    "showEnvironmentInfo" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "system_reports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "system_service_costs" (
    "id" TEXT NOT NULL,
    "reportId" TEXT NOT NULL,
    "serviceName" TEXT NOT NULL,
    "category" "CostCategory" NOT NULL DEFAULT 'OTHER',
    "provider" TEXT,
    "amount" DECIMAL(10,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "billingPeriod" "CostBillingPeriod" NOT NULL DEFAULT 'MONTHLY',
    "costType" "CostType" NOT NULL DEFAULT 'ACTUAL',
    "description" TEXT,
    "lastUpdatedDate" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP,
    "isVisible" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "system_service_costs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "user_system_report_views" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "reportId" TEXT NOT NULL,
    "revision" INTEGER NOT NULL,
    "viewedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dismissedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_system_report_views_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "system_reports_status_idx" ON "system_reports"("status");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "system_reports_enableUserVisibility_idx" ON "system_reports"("enableUserVisibility");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "system_service_costs_reportId_idx" ON "system_service_costs"("reportId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "system_service_costs_category_idx" ON "system_service_costs"("category");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "user_system_report_views_userId_idx" ON "user_system_report_views"("userId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "user_system_report_views_reportId_idx" ON "user_system_report_views"("reportId");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "user_system_report_views_userId_reportId_revision_key" ON "user_system_report_views"("userId", "reportId", "revision");

-- AddForeignKey
DO $$ BEGIN
  ALTER TABLE "system_reports" ADD CONSTRAINT "system_reports_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "system_reports" ADD CONSTRAINT "system_reports_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "system_service_costs" ADD CONSTRAINT "system_service_costs_reportId_fkey" FOREIGN KEY ("reportId") REFERENCES "system_reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "user_system_report_views" ADD CONSTRAINT "user_system_report_views_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "user_system_report_views" ADD CONSTRAINT "user_system_report_views_reportId_fkey" FOREIGN KEY ("reportId") REFERENCES "system_reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
