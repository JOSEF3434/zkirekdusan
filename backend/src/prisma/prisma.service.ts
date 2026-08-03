// backend/src/prisma/prisma.service.ts
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { neonConfig } from '@neondatabase/serverless';
import ws from 'ws';
import { PrismaNeon } from '@prisma/adapter-neon';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor() {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error(
        'Missing DATABASE_URL environment variable for Prisma connection.',
      );
    }

    neonConfig.webSocketConstructor = ws;
    super({ adapter: new PrismaNeon({ connectionString }) });
  }

  async onModuleInit() {
    await this.$connect();
    console.log('Successfully connected to the database.');
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
