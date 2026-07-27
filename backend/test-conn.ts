import 'dotenv/config';
import { PrismaService } from './src/prisma/prisma.service.js';

async function testConnection() {
  const prisma = new PrismaService();
  try {
    await prisma.$connect();
    console.log('Successfully connected via PrismaService + Neon Adapter!');
    const usersCount = await prisma.user.count();
    console.log('Current user count:', usersCount);
  } catch (err) {
    console.error('Connection error:', err);
  } finally {
    await prisma.$disconnect();
  }
}

testConnection();
