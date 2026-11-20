// prisma/seed/seed.ts
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import { DEFAULT_ROLES, AppRole } from '../../src/common/constants/roles.js';
import { PERMISSION_REGISTRY, ROLE_PERMISSIONS } from '../../src/common/constants/permissions.js';
import { EOTC_DEFAULT_EVENTS } from '../../src/modules/calendar/calendar-events.seed.js';

export async function seed(prisma: PrismaClient) {
  console.log('🌱 Starting database seed for enterprise social platform...');

  /**
   * 1. Seed Global Roles
   */
  for (const role of DEFAULT_ROLES) {
    await prisma.role.upsert({
      where: { name: role.name },
      update: { description: role.description },
      create: role,
    });
  }
  console.log('✅ Global Roles seeded (SUPER_ADMIN, ADMIN, MODERATOR, SUPPORT, USER)');

  /**
   * 2. Seed Permissions with rich metadata.
   * Upsert ensures new permissions are added; existing records get metadata refreshed.
   * This never deletes permissions (safe for running on an existing database).
   */
  for (const perm of PERMISSION_REGISTRY) {
    await prisma.permission.upsert({
      where: { name: perm.code },
      update: {
        displayName: perm.displayName,
        description: perm.description,
        category: perm.category,
        riskLevel: perm.riskLevel,
      },
      create: {
        name: perm.code,
        displayName: perm.displayName,
        description: perm.description,
        category: perm.category,
        riskLevel: perm.riskLevel,
      },
    });
  }
  console.log(`✅ ${PERMISSION_REGISTRY.length} permissions seeded with metadata`);

  /**
   * 3. Assign Role Permissions — ADDITIVE ONLY, never deletes custom assignments.
   *
   * Strategy:
   * - SUPER_ADMIN: upsert ALL permissions (idempotent full grant)
   * - Other roles: only CREATE missing RolePermission rows; existing rows are untouched.
   *
   * This preserves any permission changes made via the RBAC Management UI.
   */
  for (const [roleName, permissionNames] of Object.entries(ROLE_PERMISSIONS)) {
    const role = await prisma.role.findUnique({ where: { name: roleName } });
    if (!role) continue;

    if (permissionNames.includes('*')) {
      // SUPER_ADMIN: ensure all registered permissions are linked
      const allPermissions = await prisma.permission.findMany();
      for (const perm of allPermissions) {
        await prisma.rolePermission.upsert({
          where: {
            roleId_permissionId: { roleId: role.id, permissionId: perm.id },
          },
          update: {},
          create: { roleId: role.id, permissionId: perm.id },
        });
      }
      console.log(`✅ SUPER_ADMIN: ensured all ${allPermissions.length} permissions`);
      continue;
    }

    // For other roles: only ADD missing permission links, never remove
    let added = 0;
    for (const permName of permissionNames) {
      const perm = await prisma.permission.findUnique({ where: { name: permName } });
      if (!perm) {
        console.warn(`  ⚠️  Permission '${permName}' not found for role ${roleName} — skipping`);
        continue;
      }

      const exists = await prisma.rolePermission.findUnique({
        where: { roleId_permissionId: { roleId: role.id, permissionId: perm.id } },
      });
      if (!exists) {
        await prisma.rolePermission.create({
          data: { roleId: role.id, permissionId: perm.id },
        });
        added++;
      }
    }
    if (added > 0) {
      console.log(`✅ ${roleName}: added ${added} new default permission(s)`);
    } else {
      console.log(`   ${roleName}: no new permissions to add`);
    }
  }
  console.log('✅ Role permissions synced (additive only — admin customizations preserved)');

  /**
   * 4. Seed Super Admin Account
   */
  const superAdminRole = await prisma.role.findUnique({ where: { name: AppRole.SUPER_ADMIN } });

  const passwordHash = await bcrypt.hash('Admin@123456', 12);

  if (superAdminRole) {
    const adminUser = await prisma.user.upsert({
      where: { email: 'superadmin@platform.com' },
      update: {},
      create: {
        email: 'superadmin@platform.com',
        phoneNumber: '+10000000000',
        username: 'superadmin',
        passwordHash,
        roleId: superAdminRole.id,
        isEmailVerified: true,
        isPhoneVerified: true,
        profile: {
          create: {
            displayName: 'Super Admin',
            bio: 'Platform System Administrator',
          },
        },
      },
    });
    console.log(`✅ Super Admin created/verified: ${adminUser.email}`);
  }

  /**
   * 5. Seed Default Login Policy
   */
  const existingPolicy = await prisma.loginPolicy.findFirst();
  if (!existingPolicy) {
    await prisma.loginPolicy.create({
      data: {
        activePolicy: 'SINGLE_IDENTIFIER',
        allowEmail: true,
        allowPhone: true,
        allowUsername: true,
      },
    });
    console.log('✅ Default Login Policy seeded');
  }

  /**
   * 6. Seed Default Amharic Alephat Letters and 22 Alephats
   */
  const lettersCount = await prisma.alephatLetter.count();
  if (lettersCount === 0) {
    const { INITIAL_ALEPHAT_LETTERS } = await import('../../src/modules/alephat/alephat.seed-data.js');
    for (const item of INITIAL_ALEPHAT_LETTERS) {
      await prisma.alephatLetter.create({
        data: {
          letter: item.letter,
          name: item.name,
          order: item.order,
          defaultNote: item.defaultNote,
          pronunciationGuide: item.pronunciationGuide,
          isPublished: true,
          familyMembers: {
            create: item.familyMembers.map((fm) => ({
              glyph: fm.glyph,
              orderIndex: fm.orderIndex,
              orderName: fm.orderName,
              note: fm.note,
              pronunciation: fm.pronunciation,
              isPublished: true,
            })),
          },
        },
      });
    }
    console.log(`✅ Seeded ${INITIAL_ALEPHAT_LETTERS.length} Amharic base letters`);
  }

  const count22 = await prisma.alephat22Entry.count();
  if (count22 === 0) {
    const { INITIAL_22_ALEPHATS } = await import('../../src/modules/alephat/alephat.seed-data.js');
    for (const item of INITIAL_22_ALEPHATS) {
      await prisma.alephat22Entry.create({
        data: {
          letter: item.letter,
          title: item.title,
          meaning: item.meaning,
          order: item.order,
          note: item.note,
          supplementaryInfo: item.supplementaryInfo,
          isPublished: true,
        },
      });
    }
    console.log(`✅ Seeded ${INITIAL_22_ALEPHATS.length} 22 Alephat entries`);
  }

  /**
   * 7. Seed Initial Dictionary Languages
   */
  const defaultLanguages = [
    { code: 'en', name: 'English', nativeName: 'English', direction: 'ltr', sortOrder: 1 },
    { code: 'am', name: 'Amharic', nativeName: 'አማርኛ', direction: 'ltr', sortOrder: 2 },
    { code: 'gez', name: 'Ge\'ez', nativeName: 'ግዕዝ', direction: 'ltr', sortOrder: 3 },
    { code: 'ti', name: 'Tigrinya', nativeName: 'ትግርኛ', direction: 'ltr', sortOrder: 4 },
    { code: 'om', name: 'Oromo', nativeName: 'Afaan Oromoo', direction: 'ltr', sortOrder: 5 },
    { code: 'ar', name: 'Arabic', nativeName: 'العربية', direction: 'rtl', sortOrder: 6 },
    { code: 'fr', name: 'French', nativeName: 'Français', direction: 'ltr', sortOrder: 7 },
  ];

  for (const lang of defaultLanguages) {
    await prisma.dictionaryLanguage.upsert({
      where: { code: lang.code },
      update: {
        name: lang.name,
        nativeName: lang.nativeName,
        direction: lang.direction,
        sortOrder: lang.sortOrder,
      },
      create: {
        code: lang.code,
        name: lang.name,
        nativeName: lang.nativeName,
        direction: lang.direction,
        sortOrder: lang.sortOrder,
        isEnabled: true,
      },
    });
  }
  console.log(`✅ Seeded ${defaultLanguages.length} default dictionary languages`);

  /**
   * 8. Seed Ethiopian Orthodox Fasting & Holiday Events
   */
  for (const event of EOTC_DEFAULT_EVENTS) {
    const existing = await prisma.calendarEvent.findFirst({
      where: {
        name: event.name,
        isRecurring: event.isRecurring,
        ethiopianYear: event.ethiopianYear ?? null,
        deletedAt: null,
      },
    });

    if (!existing) {
      await prisma.calendarEvent.create({
        data: {
          name: event.name,
          nameEn: event.nameEn,
          type: event.type,
          category: event.category,
          isRecurring: event.isRecurring,
          ethiopianYear: event.ethiopianYear,
          startMonth: event.startMonth,
          startDay: event.startDay,
          endMonth: event.endMonth,
          endDay: event.endDay,
          description: event.description,
          spiritualMeaning: event.spiritualMeaning,
          fastingRules: event.fastingRules,
          primaryColor: event.primaryColor,
          isMajor: event.isMajor,
          isActive: event.isActive,
        },
      });
    }
  }
  console.log(`✅ Seeded ${EOTC_DEFAULT_EVENTS.length} default Ethiopian calendar fasts & holidays`);

  console.log('🎉 Database seed completed successfully!');
}
