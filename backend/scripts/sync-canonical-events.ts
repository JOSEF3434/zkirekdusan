import { PrismaClient } from '@prisma/client';
import { neonConfig } from '@neondatabase/serverless';
import ws from 'ws';
import { PrismaNeon } from '@prisma/adapter-neon';
import * as dotenv from 'dotenv';
dotenv.config();

import { EOTC_DEFAULT_EVENTS } from '../src/modules/calendar/calendar-events.seed.js';

async function main() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL is not defined in environment');
  }
  neonConfig.webSocketConstructor = ws;
  const adapter = new PrismaNeon({ connectionString });
  const prisma = new PrismaClient({ adapter });

  console.log(`Starting canonical events sync: ${EOTC_DEFAULT_EVENTS.length} events.`);
  let created = 0;
  let updated = 0;

  for (const item of EOTC_DEFAULT_EVENTS) {
    const existing = await prisma.calendarEvent.findFirst({
      where: {
        name: item.name,
        startMonth: item.startMonth,
        startDay: item.startDay,
        deletedAt: null,
      },
    });

    if (!existing) {
      await prisma.calendarEvent.create({
        data: {
          name: item.name,
          nameEn: item.nameEn,
          type: item.type,
          category: item.category,
          isRecurring: item.isRecurring,
          ethiopianYear: item.ethiopianYear,
          startMonth: item.startMonth,
          startDay: item.startDay,
          endMonth: item.endMonth,
          endDay: item.endDay,
          description: item.description,
          spiritualMeaning: item.spiritualMeaning,
          fastingRules: item.fastingRules,
          primaryColor: item.primaryColor,
          isMajor: item.isMajor,
          importance: item.importance ?? (item.isMajor ? 'MAJOR' : 'NORMAL'),
          isActive: item.isActive,
        },
      });
      created++;
    } else {
      await prisma.calendarEvent.update({
        where: { id: existing.id },
        data: {
          nameEn: item.nameEn,
          type: item.type,
          category: item.category,
          isRecurring: item.isRecurring,
          ethiopianYear: item.ethiopianYear,
          endMonth: item.endMonth,
          endDay: item.endDay,
          description: item.description,
          spiritualMeaning: item.spiritualMeaning,
          fastingRules: item.fastingRules,
          primaryColor: item.primaryColor,
          isMajor: item.isMajor,
          importance: item.importance ?? (item.isMajor ? 'MAJOR' : 'NORMAL'),
          isActive: item.isActive,
        },
      });
      updated++;
    }
  }

  const total = await prisma.calendarEvent.count({ where: { deletedAt: null } });
  console.log(`Sync complete. Created: ${created}, Updated: ${updated}, Total in DB: ${total}`);

  await prisma.$disconnect();
}

main().catch((err) => {
  console.error('Sync failed:', err);
  process.exit(1);
});
