// src/modules/auth-policy/auth-policy.service.ts
import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  OnModuleInit,
  Optional,
} from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { PrismaService } from '../../prisma/prisma.service.js';
import {
  DualIdentifierCombinationDto,
  LoginPolicyTypeDto,
  UpdateLoginPolicyDto,
} from './dto/update-policy.dto.js';
import { LoginPolicyResponseDto, PublicLoginPolicyDto } from './dto/policy-response.dto.js';
import { Prisma } from '@prisma/client';

// Local in-memory cache for process-level fast path
let policyCache: {
  data: PublicLoginPolicyDto;
  fetchedAt: number;
} | null = null;

const POLICY_CACHE_TTL_MS = 30_000; // 30 seconds

/**
 * AuthPolicyService
 *
 * Manages the singleton login policy record.
 * Supports distributed cache invalidation (Redis/CacheManager) across multi-instance clusters,
 * safeguards administrators against accidental self-lockout, checks impact on existing users,
 * and maintains an immutable audit trail.
 */
@Injectable()
export class AuthPolicyService implements OnModuleInit {
  private readonly logger = new Logger(AuthPolicyService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Optional() @Inject(CACHE_MANAGER) private readonly cacheManager?: Cache,
  ) {}

  /**
   * Bootstrap: ensure a default policy record exists.
   * Called once when the NestJS app starts.
   */
  async onModuleInit() {
    try {
      await this.ensureDefaultPolicy();
    } catch (err) {
      this.logger.error('Failed to initialize default login policy', err);
    }
  }

  /**
   * Idempotently create the singleton policy row.
   */
  private async ensureDefaultPolicy() {
    const existing = await this.prisma.loginPolicy.findFirst();
    if (!existing) {
      await this.prisma.loginPolicy.create({
        data: {
          activePolicy: 'SINGLE_IDENTIFIER',
          allowEmail: true,
          allowPhone: true,
          allowUsername: true,
        },
      });
      this.logger.log('Default login policy created (SINGLE_IDENTIFIER, all identifiers enabled)');
    }
  }

  /**
   * Returns the active policy from distributed/local cache or DB.
   * This is the hot path called by the login handler.
   */
  async getActivePolicy(): Promise<PublicLoginPolicyDto> {
    const now = Date.now();
    if (policyCache && now - policyCache.fetchedAt < POLICY_CACHE_TTL_MS) {
      return policyCache.data;
    }

    if (this.cacheManager) {
      try {
        const cached = await this.cacheManager.get<PublicLoginPolicyDto>('auth:login_policy');
        if (cached) {
          policyCache = { data: cached, fetchedAt: now };
          return cached;
        }
      } catch (err) {
        this.logger.warn(`Failed reading policy from distributed cache: ${err}`);
      }
    }

    await this.ensureDefaultPolicy();
    const policy = await this.prisma.loginPolicy.findFirst();

    const dto: PublicLoginPolicyDto = {
      activePolicy: policy!.activePolicy,
      allowEmail: policy!.allowEmail,
      allowPhone: policy!.allowPhone,
      allowUsername: policy!.allowUsername,
      dualCombination: policy!.dualCombination ?? null,
    };

    policyCache = { data: dto, fetchedAt: now };
    if (this.cacheManager) {
      try {
        await this.cacheManager.set('auth:login_policy', dto, POLICY_CACHE_TTL_MS);
      } catch (err) {
        this.logger.warn(`Failed writing policy to distributed cache: ${err}`);
      }
    }
    return dto;
  }

  /**
   * Returns the full policy record for admin display.
   */
  async getFullPolicy(): Promise<LoginPolicyResponseDto> {
    await this.ensureDefaultPolicy();
    const policy = await this.prisma.loginPolicy.findFirst({
      orderBy: { createdAt: 'asc' },
    });
    return {
      id: policy!.id,
      activePolicy: policy!.activePolicy,
      allowEmail: policy!.allowEmail,
      allowPhone: policy!.allowPhone,
      allowUsername: policy!.allowUsername,
      dualCombination: policy!.dualCombination ?? null,
      isLocked: policy!.isLocked,
      updatedAt: policy!.updatedAt,
    };
  }

  /**
   * Returns audit log history of policy changes.
   */
  async getPolicyAuditLogs(page = 1, limit = 30) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.prisma.loginPolicyAuditLog.findMany({
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          actor: {
            select: {
              id: true,
              username: true,
              email: true,
            },
          },
        },
      }),
      this.prisma.loginPolicyAuditLog.count(),
    ]);
    return { items, total, page, limit };
  }

  /**
   * Check impact of activating a policy on existing active users.
   */
  async checkImpact(
    activePolicy: LoginPolicyTypeDto,
    dualCombination?: DualIdentifierCombinationDto,
  ): Promise<{ affectedCount: number; totalActiveUsers: number }> {
    const totalActiveUsers = await this.prisma.user.count({
      where: { status: 'ACTIVE' },
    });

    let affectedCount = 0;
    if (activePolicy === LoginPolicyTypeDto.ALL_IDENTIFIERS) {
      affectedCount = await this.prisma.user.count({
        where: {
          status: 'ACTIVE',
          OR: [{ email: null }, { phoneNumber: null }, { username: null }],
        },
      });
    } else if (activePolicy === LoginPolicyTypeDto.DUAL_IDENTIFIER) {
      if (dualCombination === DualIdentifierCombinationDto.EMAIL_PHONE) {
        affectedCount = await this.prisma.user.count({
          where: {
            status: 'ACTIVE',
            OR: [{ email: null }, { phoneNumber: null }],
          },
        });
      } else if (dualCombination === DualIdentifierCombinationDto.EMAIL_USERNAME) {
        affectedCount = await this.prisma.user.count({
          where: {
            status: 'ACTIVE',
            OR: [{ email: null }, { username: null }],
          },
        });
      } else if (dualCombination === DualIdentifierCombinationDto.PHONE_USERNAME) {
        affectedCount = await this.prisma.user.count({
          where: {
            status: 'ACTIVE',
            OR: [{ phoneNumber: null }, { username: null }],
          },
        });
      }
    }

    return { affectedCount, totalActiveUsers };
  }

  /**
   * Updates the login policy.
   * Validates business rules, protects admin against self-lockout,
   * checks existing user population impact, persists atomically,
   * writes audit log, and invalidates cache across cluster instances.
   */
  async updatePolicy(
    dto: UpdateLoginPolicyDto,
    actorId: string,
    ipAddress?: string,
    userAgent?: string,
  ): Promise<LoginPolicyResponseDto> {
    this.validatePolicyDto(dto);

    await this.ensureDefaultPolicy();
    const existing = await this.prisma.loginPolicy.findFirst();

    if (existing?.isLocked) {
      throw new ForbiddenException(
        'The login policy is currently locked. Contact a SUPER_ADMIN to unlock.',
      );
    }

    // Security check: ensure acting administrator does not lock themselves out
    if (actorId) {
      await this.validateAdminNotLockedOut(dto, actorId);
    }

    // Security check: verify impact on existing active users
    await this.validateUserPopulationImpact(dto);

    const before = existing
      ? {
          activePolicy: existing.activePolicy,
          allowEmail: existing.allowEmail,
          allowPhone: existing.allowPhone,
          allowUsername: existing.allowUsername,
          dualCombination: existing.dualCombination,
          isLocked: existing.isLocked,
        }
      : null;

    const updateData: Prisma.LoginPolicyUpdateInput = {
      activePolicy: dto.activePolicy,
      allowEmail: dto.allowEmail ?? true,
      allowPhone: dto.allowPhone ?? true,
      allowUsername: dto.allowUsername ?? true,
      dualCombination: dto.dualCombination ?? null,
      lastModifiedBy: { connect: { id: actorId } },
    };

    const after = {
      activePolicy: dto.activePolicy,
      allowEmail: dto.allowEmail ?? true,
      allowPhone: dto.allowPhone ?? true,
      allowUsername: dto.allowUsername ?? true,
      dualCombination: dto.dualCombination ?? null,
      isLocked: existing?.isLocked ?? false,
    };

    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.loginPolicy.update({
        where: { id: existing!.id },
        data: updateData,
      });

      await tx.loginPolicyAuditLog.create({
        data: {
          actorId,
          before: before as Prisma.InputJsonValue,
          after: after as Prisma.InputJsonValue,
          reason: dto.reason,
          ipAddress,
          userAgent,
        },
      });

      return result;
    });

    // Invalidate local memory and distributed cache across all instances
    await this.invalidateCache();
    this.logger.log(`Login policy updated by ${actorId}: ${dto.activePolicy}`);

    return {
      id: updated.id,
      activePolicy: updated.activePolicy,
      allowEmail: updated.allowEmail,
      allowPhone: updated.allowPhone,
      allowUsername: updated.allowUsername,
      dualCombination: updated.dualCombination ?? null,
      isLocked: updated.isLocked,
      updatedAt: updated.updatedAt,
    };
  }

  /**
   * Emergency reset mechanism for Super Admins.
   * Restores SINGLE_IDENTIFIER policy with all identifiers enabled and unlocks the policy.
   */
  async emergencyReset(
    actorId: string,
    ipAddress?: string,
    userAgent?: string,
  ): Promise<LoginPolicyResponseDto> {
    await this.ensureDefaultPolicy();
    const existing = await this.prisma.loginPolicy.findFirst();

    const before = existing ? { ...existing } : null;

    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.loginPolicy.update({
        where: { id: existing!.id },
        data: {
          activePolicy: 'SINGLE_IDENTIFIER',
          allowEmail: true,
          allowPhone: true,
          allowUsername: true,
          dualCombination: null,
          isLocked: false,
          lastModifiedBy: { connect: { id: actorId } },
        },
      });

      await tx.loginPolicyAuditLog.create({
        data: {
          actorId,
          before: before as Prisma.InputJsonValue,
          after: {
            activePolicy: 'SINGLE_IDENTIFIER',
            allowEmail: true,
            allowPhone: true,
            allowUsername: true,
            dualCombination: null,
            isLocked: false,
          } as Prisma.InputJsonValue,
          reason: 'Emergency Policy Reset by Super Admin',
          ipAddress,
          userAgent,
        },
      });

      return result;
    });

    await this.invalidateCache();
    this.logger.warn(`Emergency login policy reset executed by ${actorId}`);

    return {
      id: updated.id,
      activePolicy: updated.activePolicy,
      allowEmail: updated.allowEmail,
      allowPhone: updated.allowPhone,
      allowUsername: updated.allowUsername,
      dualCombination: updated.dualCombination ?? null,
      isLocked: updated.isLocked,
      updatedAt: updated.updatedAt,
    };
  }

  /**
   * Validates DTO business rules before persisting.
   */
  private validatePolicyDto(dto: UpdateLoginPolicyDto) {
    if (dto.activePolicy === LoginPolicyTypeDto.DUAL_IDENTIFIER) {
      if (!dto.dualCombination) {
        throw new BadRequestException(
          'dualCombination is required when activePolicy is DUAL_IDENTIFIER',
        );
      }
    }

    if (dto.activePolicy === LoginPolicyTypeDto.SINGLE_IDENTIFIER) {
      const hasAny =
        (dto.allowEmail ?? true) ||
        (dto.allowPhone ?? true) ||
        (dto.allowUsername ?? true);
      if (!hasAny) {
        throw new BadRequestException(
          'At least one identifier must be allowed for SINGLE_IDENTIFIER policy',
        );
      }
    }
  }

  /**
   * Prevents an administrator from locking themselves out by enforcing credentials
   * that their own account does not have.
   */
  private async validateAdminNotLockedOut(
    dto: UpdateLoginPolicyDto,
    actorId: string,
  ) {
    const actor = await this.prisma.user.findUnique({
      where: { id: actorId },
      select: { id: true, email: true, phoneNumber: true, username: true },
    });
    if (!actor) return;

    if (dto.activePolicy === LoginPolicyTypeDto.DUAL_IDENTIFIER) {
      if (
        dto.dualCombination === DualIdentifierCombinationDto.EMAIL_PHONE &&
        (!actor.email || !actor.phoneNumber)
      ) {
        throw new BadRequestException(
          'Cannot activate EMAIL_PHONE policy: your administrator account lacks a registered phone number or email. You would lock yourself out.',
        );
      }
      if (
        dto.dualCombination === DualIdentifierCombinationDto.EMAIL_USERNAME &&
        (!actor.email || !actor.username)
      ) {
        throw new BadRequestException(
          'Cannot activate EMAIL_USERNAME policy: your administrator account lacks a registered username or email. You would lock yourself out.',
        );
      }
      if (
        dto.dualCombination === DualIdentifierCombinationDto.PHONE_USERNAME &&
        (!actor.phoneNumber || !actor.username)
      ) {
        throw new BadRequestException(
          'Cannot activate PHONE_USERNAME policy: your administrator account lacks a registered phone number or username. You would lock yourself out.',
        );
      }
    }

    if (dto.activePolicy === LoginPolicyTypeDto.ALL_IDENTIFIERS) {
      if (!actor.email || !actor.phoneNumber || !actor.username) {
        throw new BadRequestException(
          'Cannot activate ALL_IDENTIFIERS policy: your administrator account lacks one or more required identifiers (email, phone, or username). You would lock yourself out.',
        );
      }
    }

    if (dto.activePolicy === LoginPolicyTypeDto.SINGLE_IDENTIFIER) {
      const hasUsable =
        ((dto.allowEmail ?? true) && !!actor.email) ||
        ((dto.allowPhone ?? true) && !!actor.phoneNumber) ||
        ((dto.allowUsername ?? true) && !!actor.username);
      if (!hasUsable) {
        throw new BadRequestException(
          'Cannot activate this policy: your administrator account does not possess any of the permitted identifiers. You would lock yourself out.',
        );
      }
    }
  }

  /**
   * Verifies if activating a more restrictive policy would lock out existing users.
   * If users are affected, requires explicit acknowledgment in the request.
   */
  private async validateUserPopulationImpact(dto: UpdateLoginPolicyDto) {
    if (dto.activePolicy === LoginPolicyTypeDto.SINGLE_IDENTIFIER) {
      return;
    }

    const { affectedCount } = await this.checkImpact(
      dto.activePolicy,
      dto.dualCombination,
    );

    if (affectedCount > 0 && !dto.acknowledgeUserImpact) {
      throw new BadRequestException(
        `Activating this policy will lock out ${affectedCount} active user(s) who lack the required identifiers. Pass acknowledgeUserImpact: true to confirm and proceed.`,
      );
    }
  }

  /**
   * Utility: force-invalidate local and distributed cache.
   */
  async invalidateCache() {
    policyCache = null;
    if (this.cacheManager) {
      try {
        await this.cacheManager.del('auth:login_policy');
      } catch (err) {
        this.logger.warn(`Failed invalidating distributed policy cache: ${err}`);
      }
    }
  }
}
