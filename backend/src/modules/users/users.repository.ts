// src/modules/users/users.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { Prisma } from '@prisma/client';

@Injectable()
export class UsersRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string) {
    if (!id) return null;
    return this.prisma.user.findUnique({
      where: { id },
      include: {
        role: true,
        profile: true,
        federatedIdentities: true,
      },
    });
  }

  async findByEmail(email: string) {
    if (!email) return null;
    return this.prisma.user.findUnique({
      where: { email },
      include: {
        role: true,
        profile: true,
      },
    });
  }

  async findByPhoneNumber(phoneNumber: string) {
    if (!phoneNumber) return null;
    return this.prisma.user.findUnique({
      where: { phoneNumber },
      include: {
        role: true,
        profile: true,
      },
    });
  }

  async findByEmailOrPhone(identifier: string) {
    if (!identifier) return null;
    return this.prisma.user.findFirst({
      where: {
        OR: [{ email: identifier }, { phoneNumber: identifier }],
      },
      include: {
        role: true,
        profile: true,
      },
    });
  }

  async findByUsername(username: string) {
    if (!username) return null;
    return this.prisma.user.findUnique({
      where: { username },
      include: {
        role: true,
        profile: true,
      },
    });
  }

  async getRoleByName(name: string) {
    return this.prisma.role.findUnique({
      where: { name },
    });
  }

  async create(data: {
    email?: string;
    phoneNumber?: string;
    username?: string;
    firstName?: string;
    lastName?: string;
    passwordHash: string;
    roleId: string;
  }) {
    const displayName =
      [data.firstName, data.lastName].filter(Boolean).join(' ') ||
      data.username ||
      'User';

    return this.prisma.user.create({
      data: {
        email: data.email ?? null,
        phoneNumber: data.phoneNumber ?? null,
        username: data.username ?? null,
        passwordHash: data.passwordHash,
        roleId: data.roleId,
        profile: {
          create: {
            firstName: data.firstName ?? null,
            lastName: data.lastName ?? null,
            displayName,
          },
        },
      },
      include: {
        role: true,
        profile: true,
      },
    });
  }

  async updateUsername(userId: string, username: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { username },
    });
  }

  async updateLastLogin(userId: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        lastLoginAt: new Date(),
        failedLoginAttempts: 0,
      },
    });
  }

  async incrementFailedLogin(userId: string) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: { increment: 1 },
      },
    });

    if (user.failedLoginAttempts >= 5) {
      const lockedUntil = new Date(Date.now() + 15 * 60 * 1000); // 15 mins
      return this.prisma.user.update({
        where: { id: userId },
        data: { lockedUntil },
      });
    }

    return user;
  }

  async saveRefreshToken(userId: string, tokenHash: string, expiresAt: Date) {
    return this.prisma.refreshToken.create({
      data: { userId, tokenHash, expiresAt },
    });
  }

  async findActiveRefreshToken(userId: string) {
    return this.prisma.refreshToken.findFirst({
      where: { userId, revokedAt: null },
      orderBy: { createdAt: 'desc' },
    });
  }

  async revokeRefreshTokens(userId: string) {
    return this.prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  async createSession(data: { userId: string; expiresAt: Date }) {
    return this.prisma.session.create({
      data: {
        userId: data.userId,
        expiresAt: data.expiresAt,
        status: 'ACTIVE',
      },
    });
  }

  async revokeSessions(userId: string) {
    return this.prisma.session.updateMany({
      where: { userId, status: 'ACTIVE' },
      data: { status: 'REVOKED' },
    });
  }

  async findAll(params: { skip?: number; take?: number; search?: string }) {
    const where: Prisma.UserWhereInput = params.search
      ? {
          OR: [
            { email: { contains: params.search, mode: 'insensitive' } },
            { phoneNumber: { contains: params.search, mode: 'insensitive' } },
            { username: { contains: params.search, mode: 'insensitive' } },
          ],
        }
      : {};

    const [items, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip: params.skip ?? 0,
        take: params.take ?? 20,
        include: { role: true },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.user.count({ where }),
    ]);

    return { items, total };
  }

  async findFederatedIdentity(provider: string, providerId: string) {
    if (!provider || !providerId) return null;
    return this.prisma.federatedIdentity.findUnique({
      where: {
        provider_providerId: {
          provider,
          providerId,
        },
      },
      include: {
        user: {
          include: {
            role: true,
            profile: true,
          },
        },
      },
    });
  }

  async findFederatedIdentitiesByUserId(userId: string) {
    if (!userId) return [];
    return this.prisma.federatedIdentity.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createWithFederatedIdentity(data: {
    email?: string;
    username?: string;
    firstName?: string;
    lastName?: string;
    displayName?: string;
    avatarUrl?: string;
    roleId: string;
    provider: string;
    providerId: string;
  }) {
    const displayName =
      data.displayName ||
      [data.firstName, data.lastName].filter(Boolean).join(' ') ||
      data.username ||
      'User';

    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email: data.email ?? null,
          username: data.username ?? null,
          roleId: data.roleId,
          isEmailVerified: !!data.email,
          profile: {
            create: {
              firstName: data.firstName ?? null,
              lastName: data.lastName ?? null,
              displayName,
            },
          },
        },
        include: {
          role: true,
          profile: true,
        },
      });

      const identity = await tx.federatedIdentity.create({
        data: {
          userId: user.id,
          provider: data.provider,
          providerId: data.providerId,
          email: data.email ?? null,
        },
      });

      return { user, identity };
    });
  }

  async linkFederatedIdentity(
    userId: string,
    provider: string,
    providerId: string,
    email?: string,
  ) {
    return this.prisma.federatedIdentity.create({
      data: {
        userId,
        provider,
        providerId,
        email: email ?? null,
      },
    });
  }

  async unlinkFederatedIdentity(userId: string, provider: string) {
    return this.prisma.federatedIdentity.deleteMany({
      where: {
        userId,
        provider,
      },
    });
  }
}
