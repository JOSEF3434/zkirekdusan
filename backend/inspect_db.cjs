const fs = require('fs');
const dotenv = require('dotenv');
const ws = require('ws');
const { neonConfig } = require('@neondatabase/serverless');
const { PrismaNeon } = require('@prisma/adapter-neon');
const { PrismaClient } = require('@prisma/client');

dotenv.config({ path: '.env' });

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error('DATABASE_URL not found in .env');
  process.exit(1);
}

neonConfig.webSocketConstructor = ws;
const prisma = new PrismaClient({
  adapter: new PrismaNeon({ connectionString })
});

async function main() {
  console.log('--- Inspecting Enum Types ---');
  const enums = await prisma.$queryRawUnsafe(`
    SELECT t.typname::text as typname, array_agg(e.enumlabel::text ORDER BY e.enumsortorder) as enum_values
    FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'DictionaryProcessingStatus'
    GROUP BY t.typname;
  `);
  console.log(JSON.stringify(enums, null, 2));

  console.log('--- Inspecting Tables ---');
  const tables = await prisma.$queryRawUnsafe(`
    SELECT table_name::text
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('dictionary_languages', 'dictionary_book_configs', 'dictionary_entries', 'user_translation_histories', 'books');
  `);
  console.log(JSON.stringify(tables, null, 2));

  console.log('--- Inspecting books.isDictionary Column ---');
  const columns = await prisma.$queryRawUnsafe(`
    SELECT column_name::text, data_type::text, is_nullable::text, column_default::text
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'books'
      AND column_name = 'isDictionary';
  `);
  console.log(JSON.stringify(columns, null, 2));

  console.log('--- Inspecting Table Row Counts ---');
  for (const t of ['dictionary_languages', 'dictionary_book_configs', 'dictionary_entries', 'user_translation_histories']) {
    try {
      const count = await prisma.$queryRawUnsafe(`SELECT COUNT(*)::int as count FROM "${t}"`);
      console.log(`${t} count:`, count[0].count);
    } catch (e) {
      console.log(`${t} count failed:`, e.message);
    }
  }

  console.log('--- Inspecting Foreign Keys ---');
  const fks = await prisma.$queryRawUnsafe(`
    SELECT conname::text, conrelid::regclass::text as table_name, confrelid::regclass::text as ref_table
    FROM pg_constraint
    WHERE conname LIKE '%dictionary%' OR conname LIKE '%translation%';
  `);
  console.log(JSON.stringify(fks, null, 2));

  console.log('--- Inspecting Indexes ---');
  const indexes = await prisma.$queryRawUnsafe(`
    SELECT indexname::text, tablename::text
    FROM pg_indexes
    WHERE tablename IN ('dictionary_languages', 'dictionary_book_configs', 'dictionary_entries', 'user_translation_histories')
       OR indexname = 'books_isDictionary_idx';
  `);
  console.log(JSON.stringify(indexes, null, 2));
}

main()
  .catch((e) => {
    console.error('Inspection error:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
