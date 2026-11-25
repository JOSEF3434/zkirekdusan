import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { AdminAuditService } from '../admin/services/admin-audit.service.js';
import {
  CreateSystemReportDto,
  ServiceCostItemDto,
} from './dto/create-system-report.dto.js';
import { UpdateSystemReportDto } from './dto/update-system-report.dto.js';
import { UpdateVisibilityDto } from './dto/update-visibility.dto.js';
import {
  CreateServiceCostDto,
  UpdateServiceCostDto,
} from './dto/service-cost.dto.js';
import {
  PublicSystemReportDto,
  PublicServerInfoDto,
  PublicDatabaseInfoDto,
  PublicApiInfoDto,
  PublicDeploymentInfoDto,
  PublicCostItemDto,
} from './dto/public-system-report.dto.js';
import {
  SystemReport,
  SystemReportStatus,
  SystemReportDisplayMode,
  SystemServiceCost,
} from '@prisma/client';

@Injectable()
export class SystemReportService {
  private readonly logger = new Logger(SystemReportService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AdminAuditService,
  ) {}

  /**
   * Retrieves the most recent report or automatically initializes a default draft
   * if no report has been created yet.
   */
  async getLatestOrCreate(adminId?: string): Promise<SystemReport & { costs: SystemServiceCost[] }> {
    let report = await this.prisma.systemReport.findFirst({
      orderBy: { createdAt: 'desc' },
      include: {
        costs: {
          orderBy: { createdAt: 'asc' },
        },
        createdBy: {
          select: { id: true, username: true, email: true },
        },
        updatedBy: {
          select: { id: true, username: true, email: true },
        },
      },
    });

    if (!report) {
      this.logger.log('No system report found. Initializing initial draft report.');
      report = await this.prisma.systemReport.create({
        data: {
          title: 'Zikre Kedusan Infrastructure & System Report',
          summary: 'Platform infrastructure, hosting details, and service operational status.',
          status: SystemReportStatus.DRAFT,
          revision: 1,
          enableUserVisibility: false,
          displayMode: SystemReportDisplayMode.SETTINGS_ONLY,
          createdById: adminId,
          updatedById: adminId,
        },
        include: {
          costs: true,
          createdBy: {
            select: { id: true, username: true, email: true },
          },
          updatedBy: {
            select: { id: true, username: true, email: true },
          },
        },
      });

      if (adminId) {
        await this.audit.emit({
          actorId: adminId,
          action: 'SYSTEM_REPORT_INITIALIZED',
          resource: 'SYSTEM_REPORT',
          targetType: 'SYSTEM_REPORT',
          targetId: report.id,
          after: { title: report.title, status: report.status },
        });
      }
    }

    return report;
  }

  /**
   * Retrieves a specific report by ID for administrative management.
   */
  async getAdminReportById(id: string): Promise<SystemReport & { costs: SystemServiceCost[] }> {
    const report = await this.prisma.systemReport.findUnique({
      where: { id },
      include: {
        costs: {
          orderBy: { createdAt: 'asc' },
        },
        createdBy: {
          select: { id: true, username: true, email: true },
        },
        updatedBy: {
          select: { id: true, username: true, email: true },
        },
      },
    });

    if (!report) {
      throw new NotFoundException(`System report with ID ${id} not found`);
    }

    return report;
  }

  /**
   * Lists all system reports (history / revisions).
   */
  async getAllReports() {
    return this.prisma.systemReport.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        costs: true,
        createdBy: {
          select: { id: true, username: true, email: true },
        },
        updatedBy: {
          select: { id: true, username: true, email: true },
        },
      },
    });
  }

  /**
   * Creates a new draft system report.
   */
  async createReport(adminId: string, dto: CreateSystemReportDto) {
    const { costs, lastDeploymentDate, ...data } = dto;

    const report = await this.prisma.systemReport.create({
      data: {
        ...data,
        lastDeploymentDate: lastDeploymentDate ? new Date(lastDeploymentDate) : undefined,
        status: SystemReportStatus.DRAFT,
        revision: 1,
        enableUserVisibility: false, // MANDATORY: default false!
        createdById: adminId,
        updatedById: adminId,
        costs: costs && costs.length > 0
          ? {
              create: costs.map((c) => ({
                serviceName: c.serviceName,
                category: c.category,
                provider: c.provider,
                amount: c.amount,
                currency: c.currency ?? 'USD',
                billingPeriod: c.billingPeriod,
                costType: c.costType,
                description: c.description,
                lastUpdatedDate: c.lastUpdatedDate ? new Date(c.lastUpdatedDate) : new Date(),
                isVisible: false, // MANDATORY: default false!
              })),
            }
          : undefined,
      },
      include: {
        costs: true,
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_CREATED',
      resource: 'SYSTEM_REPORT',
      targetType: 'SYSTEM_REPORT',
      targetId: report.id,
      after: { title: report.title, status: report.status },
    });

    return report;
  }

  /**
   * Updates an existing report data fields.
   */
  async updateReport(adminId: string, id: string, dto: UpdateSystemReportDto) {
    const existing = await this.getAdminReportById(id);
    const { costs, lastDeploymentDate, ...data } = dto;

    const updated = await this.prisma.systemReport.update({
      where: { id },
      data: {
        ...data,
        lastDeploymentDate: lastDeploymentDate ? new Date(lastDeploymentDate) : undefined,
        updatedById: adminId,
      },
      include: {
        costs: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_UPDATED',
      resource: 'SYSTEM_REPORT',
      targetType: 'SYSTEM_REPORT',
      targetId: id,
      before: { title: existing.title, status: existing.status },
      after: { title: updated.title, status: updated.status },
    });

    return updated;
  }

  /**
   * Updates visibility and display settings with strict audit logging.
   */
  async updateVisibility(adminId: string, id: string, dto: UpdateVisibilityDto) {
    const existing = await this.getAdminReportById(id);

    const updated = await this.prisma.systemReport.update({
      where: { id },
      data: {
        ...dto,
        updatedById: adminId,
      },
      include: {
        costs: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_VISIBILITY_CHANGED',
      resource: 'SYSTEM_REPORT',
      targetType: 'SYSTEM_REPORT',
      targetId: id,
      before: {
        enableUserVisibility: existing.enableUserVisibility,
        displayMode: existing.displayMode,
        displayServerInfo: existing.displayServerInfo,
        displayDatabaseInfo: existing.displayDatabaseInfo,
        displayApiInfo: existing.displayApiInfo,
        displayDeploymentInfo: existing.displayDeploymentInfo,
        displayAdditionalCosts: existing.displayAdditionalCosts,
      },
      after: {
        enableUserVisibility: updated.enableUserVisibility,
        displayMode: updated.displayMode,
        displayServerInfo: updated.displayServerInfo,
        displayDatabaseInfo: updated.displayDatabaseInfo,
        displayApiInfo: updated.displayApiInfo,
        displayDeploymentInfo: updated.displayDeploymentInfo,
        displayAdditionalCosts: updated.displayAdditionalCosts,
      },
    });

    return updated;
  }

  /**
   * Publishes the system report.
   * Increments the revision number and stamps publishedAt timestamp.
   */
  async publishReport(adminId: string, id: string, displayMode?: SystemReportDisplayMode) {
    const existing = await this.getAdminReportById(id);

    const newRevision = (existing.revision ?? 0) + 1;

    const published = await this.prisma.systemReport.update({
      where: { id },
      data: {
        status: SystemReportStatus.PUBLISHED,
        revision: newRevision,
        publishedAt: new Date(),
        unpublishedAt: null,
        displayMode: displayMode ?? existing.displayMode,
        updatedById: adminId,
      },
      include: {
        costs: true,
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_PUBLISHED',
      resource: 'SYSTEM_REPORT',
      targetType: 'SYSTEM_REPORT',
      targetId: id,
      before: { status: existing.status, revision: existing.revision },
      after: {
        status: published.status,
        revision: published.revision,
        enableUserVisibility: published.enableUserVisibility,
        publishedAt: published.publishedAt,
      },
    });

    return published;
  }

  /**
   * Unpublishes the system report.
   */
  async unpublishReport(adminId: string, id: string) {
    const existing = await this.getAdminReportById(id);

    const unpublished = await this.prisma.systemReport.update({
      where: { id },
      data: {
        status: SystemReportStatus.UNPUBLISHED,
        unpublishedAt: new Date(),
        updatedById: adminId,
      },
      include: {
        costs: true,
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_UNPUBLISHED',
      resource: 'SYSTEM_REPORT',
      targetType: 'SYSTEM_REPORT',
      targetId: id,
      before: { status: existing.status },
      after: { status: unpublished.status, unpublishedAt: unpublished.unpublishedAt },
    });

    return unpublished;
  }

  /**
   * Adds an additional service cost item to a report.
   */
  async addCostItem(adminId: string, reportId: string, dto: CreateServiceCostDto) {
    await this.getAdminReportById(reportId);

    const cost = await this.prisma.systemServiceCost.create({
      data: {
        reportId,
        serviceName: dto.serviceName,
        category: dto.category,
        provider: dto.provider,
        amount: dto.amount,
        currency: dto.currency ?? 'USD',
        billingPeriod: dto.billingPeriod,
        costType: dto.costType,
        description: dto.description,
        lastUpdatedDate: dto.lastUpdatedDate ? new Date(dto.lastUpdatedDate) : new Date(),
        isVisible: dto.isVisible ?? false, // MANDATORY: default false!
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_COST_ADDED',
      resource: 'SYSTEM_SERVICE_COST',
      targetType: 'SYSTEM_SERVICE_COST',
      targetId: cost.id,
      after: { serviceName: cost.serviceName, amount: Number(cost.amount) },
    });

    return cost;
  }

  /**
   * Updates an existing service cost item.
   */
  async updateCostItem(adminId: string, costId: string, dto: UpdateServiceCostDto) {
    const existing = await this.prisma.systemServiceCost.findUnique({
      where: { id: costId },
    });
    if (!existing) {
      throw new NotFoundException(`Cost item with ID ${costId} not found`);
    }

    const { lastUpdatedDate, ...data } = dto;

    const updated = await this.prisma.systemServiceCost.update({
      where: { id: costId },
      data: {
        ...data,
        lastUpdatedDate: lastUpdatedDate ? new Date(lastUpdatedDate) : undefined,
      },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_COST_UPDATED',
      resource: 'SYSTEM_SERVICE_COST',
      targetType: 'SYSTEM_SERVICE_COST',
      targetId: costId,
      before: { serviceName: existing.serviceName, amount: Number(existing.amount), isVisible: existing.isVisible },
      after: { serviceName: updated.serviceName, amount: Number(updated.amount), isVisible: updated.isVisible },
    });

    return updated;
  }

  /**
   * Deletes a service cost item.
   */
  async deleteCostItem(adminId: string, costId: string) {
    const existing = await this.prisma.systemServiceCost.findUnique({
      where: { id: costId },
    });
    if (!existing) {
      throw new NotFoundException(`Cost item with ID ${costId} not found`);
    }

    await this.prisma.systemServiceCost.delete({
      where: { id: costId },
    });

    await this.audit.emit({
      actorId: adminId,
      action: 'SYSTEM_REPORT_COST_DELETED',
      resource: 'SYSTEM_SERVICE_COST',
      targetType: 'SYSTEM_SERVICE_COST',
      targetId: costId,
      before: { serviceName: existing.serviceName, amount: Number(existing.amount) },
    });

    return { success: true };
  }

  /**
   * Previews what an ordinary user will see for the specified report.
   * Ignores the global enableUserVisibility flag so the admin can inspect the filtered output.
   */
  async previewPublicReport(id: string): Promise<PublicSystemReportDto> {
    const report = await this.getAdminReportById(id);
    return this.buildSanitizedReport(report, false);
  }

  /**
   * Retrieves the active published system report for ordinary users.
   * If global user visibility is disabled or no report is published, returns available: false.
   * All hidden categories, fields, and cost items are completely stripped at the server level.
   */
  async getActivePublicReport(userId?: string): Promise<{ available: boolean; report: PublicSystemReportDto | null }> {
    const report = await this.prisma.systemReport.findFirst({
      where: {
        status: SystemReportStatus.PUBLISHED,
        enableUserVisibility: true, // MANDATORY: Must be explicitly enabled!
      },
      orderBy: { publishedAt: 'desc' },
      include: {
        costs: {
          where: { isVisible: true }, // Only visible cost items queried
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!report) {
      return { available: false, report: null };
    }

    let hasDismissed = false;
    if (userId) {
      const view = await this.prisma.userSystemReportView.findUnique({
        where: {
          userId_reportId_revision: {
            userId,
            reportId: report.id,
            revision: report.revision,
          },
        },
      });
      hasDismissed = !!(view && view.dismissedAt);
    }

    const sanitized = this.buildSanitizedReport(report, hasDismissed);
    return { available: true, report: sanitized };
  }

  /**
   * Records that an authenticated user viewed and dismissed a specific revision of the report.
   */
  async recordUserDismissal(userId: string, reportId: string, revision: number) {
    const report = await this.prisma.systemReport.findUnique({
      where: { id: reportId },
      select: { id: true, revision: true },
    });

    if (!report) {
      throw new NotFoundException(`Report ${reportId} not found`);
    }

    return this.prisma.userSystemReportView.upsert({
      where: {
        userId_reportId_revision: {
          userId,
          reportId,
          revision,
        },
      },
      create: {
        userId,
        reportId,
        revision,
        viewedAt: new Date(),
        dismissedAt: new Date(),
      },
      update: {
        dismissedAt: new Date(),
      },
    });
  }

  /**
   * Strict server-side field-level filter.
   * Ensures that unapproved or unconfigured fields are NEVER exposed to the public API.
   */
  private buildSanitizedReport(
    report: SystemReport & { costs?: SystemServiceCost[] },
    hasDismissed: boolean,
  ): PublicSystemReportDto {
    // 1. Server info filtering
    let server: PublicServerInfoDto | undefined = undefined;
    if (report.displayServerInfo) {
      const serverData: PublicServerInfoDto = {};
      if (report.showServerProvider && report.serverProvider) serverData.provider = report.serverProvider;
      if (report.showServerServiceName && report.serverServiceName) serverData.serviceName = report.serverServiceName;
      if (report.showServerLocation && report.serverLocation) serverData.location = report.serverLocation;
      if (report.showServerRegion && report.serverRegion) serverData.region = report.serverRegion;
      if (report.showServerPlan && report.serverPlan) serverData.plan = report.serverPlan;
      if (report.showServerHostingType && report.serverHostingType) serverData.hostingType = report.serverHostingType;
      if (report.showServerCpu && report.serverCpu) serverData.cpu = report.serverCpu;
      if (report.showServerRam && report.serverRam) serverData.ram = report.serverRam;
      if (report.showServerDiskCapacity && report.serverDiskCapacity) serverData.diskCapacity = report.serverDiskCapacity;
      if (report.showServerAvailableStorage && report.serverAvailableStorage) serverData.availableStorage = report.serverAvailableStorage;
      if (report.showServerStatus && report.serverStatus) serverData.status = report.serverStatus;
      if (report.showServerHealth && report.serverHealth) serverData.health = report.serverHealth;
      if (report.showServerUptime && report.serverUptime) serverData.uptime = report.serverUptime;
      if (report.showServerMaintenanceInfo && report.serverMaintenanceInfo) serverData.maintenanceInfo = report.serverMaintenanceInfo;
      if (report.showServerBackupConfig && report.serverBackupConfig) serverData.backupConfig = report.serverBackupConfig;
      if (report.showServerBackupStorage && report.serverBackupStorage) serverData.backupStorage = report.serverBackupStorage;

      // Server Costs: Only if displayServerCosts is ON and field is ON
      if (report.displayServerCosts) {
        if (report.showServerMonthlyCost && report.serverMonthlyCost !== null) {
          serverData.monthlyCost = Number(report.serverMonthlyCost);
        }
        if (report.showServerYearlyCost && report.serverYearlyCost !== null) {
          serverData.yearlyCost = Number(report.serverYearlyCost);
        }
        if (serverData.monthlyCost !== undefined || serverData.yearlyCost !== undefined) {
          serverData.currency = report.serverCostCurrency;
        }
      }

      if (Object.keys(serverData).length > 0) {
        server = serverData;
      }
    }

    // 2. Database info filtering
    let database: PublicDatabaseInfoDto | undefined = undefined;
    if (report.displayDatabaseInfo) {
      const dbData: PublicDatabaseInfoDto = {};
      if (report.showDbProvider && report.dbProvider) dbData.provider = report.dbProvider;
      if (report.showDbEngine && report.dbEngine) dbData.engine = report.dbEngine;
      if (report.showDbHostingPlan && report.dbHostingPlan) dbData.hostingPlan = report.dbHostingPlan;
      if (report.showDbInfrastructure && report.dbInfrastructure) dbData.infrastructure = report.dbInfrastructure;
      if (report.showDbStorageUsage && report.dbStorageUsage) dbData.storageUsage = report.dbStorageUsage;
      if (report.showDbStorageCapacity && report.dbStorageCapacity) dbData.storageCapacity = report.dbStorageCapacity;
      if (report.showDbBackupStatus && report.dbBackupStatus) dbData.backupStatus = report.dbBackupStatus;
      if (report.showDbHealth && report.dbHealth) dbData.health = report.dbHealth;
      if (report.showDbAvailability && report.dbAvailability) dbData.availability = report.dbAvailability;

      // DB Costs
      if (report.displayDatabaseCosts) {
        if (report.showDbMonthlyCost && report.dbMonthlyCost !== null) {
          dbData.monthlyCost = Number(report.dbMonthlyCost);
        }
        if (report.showDbYearlyCost && report.dbYearlyCost !== null) {
          dbData.yearlyCost = Number(report.dbYearlyCost);
        }
        if (dbData.monthlyCost !== undefined || dbData.yearlyCost !== undefined) {
          dbData.currency = report.dbCostCurrency;
        }
      }

      if (Object.keys(dbData).length > 0) {
        database = dbData;
      }
    }

    // 3. API info filtering
    let api: PublicApiInfoDto | undefined = undefined;
    if (report.displayApiInfo) {
      const apiData: PublicApiInfoDto = {};
      if (report.showApiServiceName && report.apiServiceName) apiData.serviceName = report.apiServiceName;
      if (report.showApiAvailability && report.apiAvailability) apiData.availability = report.apiAvailability;
      if (report.showApiStatus && report.apiStatus) apiData.status = report.apiStatus;
      if (report.showApiResponseTime && report.apiResponseTime) apiData.responseTime = report.apiResponseTime;
      if (report.showApiUsageStats && report.apiUsageStats) apiData.usageStats = report.apiUsageStats;

      // API Costs
      if (report.displayApiCosts) {
        if (report.showApiHostingCost && report.apiHostingCost !== null) {
          apiData.hostingCost = Number(report.apiHostingCost);
        }
        if (report.showApiExternalCost && report.apiExternalCost !== null) {
          apiData.externalCost = Number(report.apiExternalCost);
        }
        if (apiData.hostingCost !== undefined || apiData.externalCost !== undefined) {
          apiData.currency = report.apiCostCurrency;
        }
      }

      if (Object.keys(apiData).length > 0) {
        api = apiData;
      }
    }

    // 4. Deployment info filtering
    let deployment: PublicDeploymentInfoDto | undefined = undefined;
    if (report.displayDeploymentInfo) {
      const depData: PublicDeploymentInfoDto = {};
      if (report.showDeploymentProvider && report.deploymentProvider) depData.provider = report.deploymentProvider;
      if (report.showDeploymentEnvironment && report.deploymentEnvironment) depData.environment = report.deploymentEnvironment;
      if (report.showAppVersion && report.appVersion) depData.appVersion = report.appVersion;
      if (report.showLastDeploymentDate && report.lastDeploymentDate) depData.lastDeploymentDate = report.lastDeploymentDate.toISOString();
      if (report.showBuildStatus && report.buildStatus) depData.buildStatus = report.buildStatus;
      if (report.showEnvironmentInfo && report.environmentInfo) depData.environmentInfo = report.environmentInfo;

      // Deployment Costs
      if (report.displayDeploymentCosts) {
        if (report.showDeploymentCost && report.deploymentCost !== null) {
          depData.deploymentCost = Number(report.deploymentCost);
          depData.currency = report.deploymentCostCurrency;
        }
      }

      if (Object.keys(depData).length > 0) {
        deployment = depData;
      }
    }

    // 5. Additional service costs filtering
    const costs: PublicCostItemDto[] = [];
    if (report.displayAdditionalCosts && report.costs) {
      for (const cost of report.costs) {
        if (cost.isVisible) {
          costs.push({
            id: cost.id,
            serviceName: cost.serviceName,
            category: cost.category,
            provider: cost.provider ?? undefined,
            amount: Number(cost.amount),
            currency: cost.currency,
            billingPeriod: cost.billingPeriod,
            costType: cost.costType,
            description: cost.description ?? undefined,
            lastUpdatedDate: cost.lastUpdatedDate ? cost.lastUpdatedDate.toISOString() : undefined,
          });
        }
      }
    }

    return {
      id: report.id,
      title: report.title,
      summary: report.summary ?? undefined,
      notes: report.notes ?? undefined,
      revision: report.revision,
      publishedAt: report.publishedAt ? report.publishedAt.toISOString() : new Date().toISOString(),
      displayMode: report.displayMode,
      server,
      database,
      api,
      deployment,
      costs,
      hasDismissed,
    };
  }
}
