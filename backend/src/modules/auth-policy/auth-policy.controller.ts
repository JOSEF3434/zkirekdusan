// src/modules/auth-policy/auth-policy.controller.ts
import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { PermissionsGuard } from '../../common/guards/permissions.guard.js';
import { Permissions } from '../../common/decorators/permissions.decorator.js';
import { Public } from '../../common/decorators/public.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { PERMISSIONS } from '../../common/constants/permissions.js';
import { AuthPolicyService } from './auth-policy.service.js';
import {
  DualIdentifierCombinationDto,
  LoginPolicyTypeDto,
  UpdateLoginPolicyDto,
} from './dto/update-policy.dto.js';
import { LoginPolicyResponseDto, PublicLoginPolicyDto } from './dto/policy-response.dto.js';
import type { Request } from 'express';

@ApiTags('Login Policy')
@Controller('auth-policy')
export class AuthPolicyController {
  constructor(private readonly policyService: AuthPolicyService) {}

  /**
   * GET /auth-policy/config
   * Public — returns only the safe subset of policy needed by the login form.
   * No secrets, no admin settings.
   */
  @Public()
  @Get('config')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Get public login policy configuration (for login form)',
    description:
      'Returns the current login identifier requirements without exposing admin settings.',
  })
  @ApiResponse({ status: 200, type: PublicLoginPolicyDto })
  async getPublicConfig(): Promise<PublicLoginPolicyDto> {
    return this.policyService.getActivePolicy();
  }

  /**
   * GET /auth-policy
   * Admin — returns full policy record with metadata.
   */
  @Get()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions(PERMISSIONS.AUTH_POLICY.VIEW)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get full login policy record (admin)' })
  @ApiResponse({ status: 200, type: LoginPolicyResponseDto })
  @ApiResponse({ status: 403, description: 'Forbidden — requires auth.login-policy.view' })
  async getPolicy(): Promise<LoginPolicyResponseDto> {
    return this.policyService.getFullPolicy();
  }

  /**
   * GET /auth-policy/impact-check
   * Admin — check how many existing active users lack identifiers for a proposed policy.
   */
  @Get('impact-check')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions(PERMISSIONS.AUTH_POLICY.VIEW)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Check impact of a proposed login policy on existing users' })
  async checkImpact(
    @Query('activePolicy') activePolicy: LoginPolicyTypeDto,
    @Query('dualCombination') dualCombination?: DualIdentifierCombinationDto,
  ) {
    return this.policyService.checkImpact(activePolicy, dualCombination);
  }

  /**
   * PUT /auth-policy
   * Admin — update the login policy.
   * Requires: auth.login-policy.manage permission.
   */
  @Put()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions(PERMISSIONS.AUTH_POLICY.MANAGE)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update the platform login policy (admin)',
    description:
      'Atomically updates the active login policy. Records an audit log entry. ' +
      'Invalidates cache across cluster instances so new logins immediately use the new policy.',
  })
  @ApiResponse({ status: 200, type: LoginPolicyResponseDto })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 403, description: 'Forbidden — requires auth.login-policy.manage' })
  async updatePolicy(
    @Body() dto: UpdateLoginPolicyDto,
    @CurrentUser('sub') actorId: string,
    @Req() req: Request,
  ): Promise<LoginPolicyResponseDto> {
    const ipAddress =
      (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ||
      req.socket?.remoteAddress ||
      undefined;
    const userAgent = (req.headers['user-agent'] as string) || undefined;
    return this.policyService.updatePolicy(dto, actorId, ipAddress, userAgent);
  }

  /**
   * POST /auth-policy/emergency-reset
   * Admin — emergency reset login policy to SINGLE_IDENTIFIER with all identifiers enabled.
   */
  @Post('emergency-reset')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions(PERMISSIONS.AUTH_POLICY.MANAGE)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Emergency reset login policy to default safe policy (admin)' })
  async emergencyReset(
    @CurrentUser('sub') actorId: string,
    @Req() req: Request,
  ): Promise<LoginPolicyResponseDto> {
    const ipAddress =
      (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ||
      req.socket?.remoteAddress ||
      undefined;
    const userAgent = (req.headers['user-agent'] as string) || undefined;
    return this.policyService.emergencyReset(actorId, ipAddress, userAgent);
  }

  /**
   * GET /auth-policy/audit-logs
   * Admin — returns audit trail for all policy changes.
   */
  @Get('audit-logs')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions(PERMISSIONS.AUTH_POLICY.VIEW)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get login policy audit log history (admin)' })
  async getAuditLogs(
    @Query('page') page = 1,
    @Query('limit') limit = 30,
  ) {
    return this.policyService.getPolicyAuditLogs(
      Number(page),
      Number(limit),
    );
  }
}
