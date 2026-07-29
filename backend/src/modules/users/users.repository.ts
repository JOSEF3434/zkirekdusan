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
    username: string;
    passwordHash: string;
    roleId: string;
  }) {
    return this.prisma.user.create({
      data: {
        email: data.email ?? null,
        phoneNumber: data.phoneNumber ?? null,
        username: data.username,
        passwordHash: data.passwordHash,
        roleId: data.roleId,
        profile: {
          create: {
            displayName: data.username,
          },
        },
      },
      include: {
        role: true,
        profile: true,
      },
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
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: { increment: 1 },
      },
    });
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
}
