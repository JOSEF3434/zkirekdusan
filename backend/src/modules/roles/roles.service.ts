// src/modules/roles/roles.service.ts

import { PrismaService } from '../../prisma/prisma.service.js';
import { Injectable } from '@nestjs/common';

@Injectable()
export class RolesService {
  constructor(private readonly prisma: PrismaService) {}

  async getDefaultRole() {
    return this.prisma.role.findUnique({
      where: {
        name: 'USER',
      },
    });
  }
}
