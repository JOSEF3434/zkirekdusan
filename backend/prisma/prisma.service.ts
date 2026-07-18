import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  // Remove the constructor entirely!
  // Prisma will automatically look for process.env.DATABASE_URL

  async onModuleInit() {
    await this.$connect();
    console.log('Successfully connected to the database.');
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
