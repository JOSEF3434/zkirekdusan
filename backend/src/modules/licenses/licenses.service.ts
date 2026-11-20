// src/modules/licenses/licenses.service.ts
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { ValidateLicenseDto } from './dto/validate-license.dto.js';
import { ActivateLicenseDto } from './dto/activate-license.dto.js';
import { CreateLicenseDto } from './dto/create-license.dto.js';
import { randomBytes } from 'crypto';

@Injectable()
export class LicensesService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Admin: generate a new license code ───────────────────────────────────
  async createLicense(dto: CreateLicenseDto) {
    const code = this._generateActivationCode();
    return this.prisma.appLicense.create({
      data: {
        activationCode: code,
        note: dto.note,
        maxDevices: dto.maxDevices ?? 1,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
        status: 'PENDING',
      },
    });
  }

  // ── Validate: called on every app launch ─────────────────────────────────
  async validate(dto: ValidateLicenseDto) {
    const device = await this.prisma.deviceRegistration.findFirst({
      where: { deviceId: dto.deviceId, isActive: true },
      include: { license: true },
    });

    if (!device) {
      return { isValid: false, reason: 'NOT_REGISTERED' };
    }

    const { license } = device;

    if (license.status === 'REVOKED') {
      return { isValid: false, reason: 'REVOKED' };
    }

    if (
      license.status === 'EXPIRED' ||
      (license.expiresAt && license.expiresAt < new Date())
    ) {
      await this.prisma.appLicense.update({
        where: { id: license.id },
        data: { status: 'EXPIRED' },
      });
      return {
        isValid: false,
        reason: 'EXPIRED',
        expiresAt: license.expiresAt,
      };
    }

    if (license.status !== 'ACTIVE') {
      return { isValid: false, reason: 'PENDING' };
    }

    // Update last seen timestamp and app version
    await this.prisma.deviceRegistration.update({
      where: { id: device.id },
      data: { lastSeenAt: new Date(), appVersion: dto.appVersion },
    });

    const daysRemaining =
      license.expiresAt !== null
        ? Math.max(
            0,
            Math.ceil(
              (license.expiresAt.getTime() - Date.now()) / 86_400_000,
            ),
          )
        : null;

    return {
      isValid: true,
      expiresAt: license.expiresAt,
      daysRemaining,
      licenseId: license.id,
    };
  }

  // ── Activate: bind a device to a license using activation code ────────────
  async activate(dto: ActivateLicenseDto) {
    const license = await this.prisma.appLicense.findUnique({
      where: { activationCode: dto.activationCode },
      include: { devices: { where: { isActive: true } } },
    });

    if (!license) throw new NotFoundException('Invalid activation code');
    if (license.status === 'REVOKED')
      throw new ForbiddenException('License has been revoked');
    if (license.status === 'EXPIRED')
      throw new ForbiddenException('License has expired');

    // Check if device is already registered under THIS license (idempotent)
    const existing = await this.prisma.deviceRegistration.findUnique({
      where: {
        deviceId_licenseId: {
          deviceId: dto.deviceId,
          licenseId: license.id,
        },
      },
    });

    if (existing && existing.isActive) {
      return { activated: true, licenseId: license.id };
    }

    // Check max devices limit
    if (license.devices.length >= license.maxDevices) {
      throw new BadRequestException(
        'Maximum device limit reached for this license',
      );
    }

    // Register device
    await this.prisma.deviceRegistration.upsert({
      where: {
        deviceId_licenseId: {
          deviceId: dto.deviceId,
          licenseId: license.id,
        },
      },
      create: {
        deviceId: dto.deviceId,
        platform: dto.platform,
        appVersion: dto.appVersion,
        licenseId: license.id,
        isActive: true,
      },
      update: {
        isActive: true,
        lastSeenAt: new Date(),
        appVersion: dto.appVersion,
      },
    });

    // Auto-activate license on first device registration
    if (license.status === 'PENDING') {
      await this.prisma.appLicense.update({
        where: { id: license.id },
        data: { status: 'ACTIVE' },
      });
    }

    return { activated: true, licenseId: license.id };
  }

  // ── Admin: list all licenses with device counts ───────────────────────────
  async listAll() {
    return this.prisma.appLicense.findMany({
      include: { devices: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  // ── Admin: get one license ────────────────────────────────────────────────
  async findOne(id: string) {
    const license = await this.prisma.appLicense.findUnique({
      where: { id },
      include: { devices: true },
    });
    if (!license) throw new NotFoundException('License not found');
    return license;
  }

  // ── Admin: revoke a license (immediately blocks all devices) ─────────────
  async revoke(id: string) {
    await this.findOne(id);
    return this.prisma.appLicense.update({
      where: { id },
      data: { status: 'REVOKED' },
    });
  }

  // ── Admin: deactivate a specific device ───────────────────────────────────
  async deactivateDevice(deviceRegistrationId: string) {
    return this.prisma.deviceRegistration.update({
      where: { id: deviceRegistrationId },
      data: { isActive: false },
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  private _generateActivationCode(): string {
    const segment = () =>
      randomBytes(2).toString('hex').toUpperCase().substring(0, 4);
    return `${segment()}-${segment()}-${segment()}-${segment()}`;
  }
}
