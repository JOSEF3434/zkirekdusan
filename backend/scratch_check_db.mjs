import { PrismaClient } from '@prisma/client';
import { neonConfig } from '@neondatabase/serverless';
import ws from 'ws';
import { PrismaNeon } from '@prisma/adapter-neon';
import dotenv from 'dotenv';
dotenv.config();

BigInt.prototype.toJSON = function () {
  const intVal = Number(this.valueOf());
  return Number.isSafeInteger(intVal) ? intVal : this.toString();
};

const connectionString = process.env.DATABASE_URL;
neonConfig.webWebSocketConstructor = ws;
neonConfig.webSocketConstructor = ws;
const prisma = new PrismaClient({ adapter: new PrismaNeon({ connectionString }) });

async function main() {
  const notes = await prisma.calendarNote.findMany({
    include: {
      media: {
        include: {
          file: true,
        },
      },
    },
  });
  console.log('=== CALENDAR NOTES ===');
  for (const n of notes) {
    console.log(`Note ID: ${n.id}, Title: ${n.title}, Media count: ${n.media.length}`);
    for (const m of n.media) {
      console.log('  Media:', JSON.stringify(m, null, 2));
    }
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
