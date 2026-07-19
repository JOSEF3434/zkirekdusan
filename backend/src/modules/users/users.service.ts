// src/modules/users/users.service.ts

import { Injectable } from '@nestjs/common';
import { PrismaService } from 'prisma/prisma.service.js';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findByEmail(email: string) {
    return this.prisma.user.findUnique({
      where: { email },
      include: {
        role: true,
        profile: true,
      },
    });
  }

  async findByUsername(username: string) {
    return this.prisma.user.findUnique({
      where: { username },
    });
  }

  async findById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
      include: {
        role: true,
        profile: true,
      },
    });
  }

  async create(data: {
    email: string;
    username: string;
    passwordHash: string;
    roleId: string;
  }) {
    return this.prisma.user.create({
      data: {
        ...data,

        profile: {
          create: {},
        },
      },
      include: {
        profile: true,
        role: true,
      },
    });
  }
}
