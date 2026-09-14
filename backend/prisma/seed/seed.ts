// prisma/seed/seed.ts
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import { DEFAULT_ROLES, AppRole } from '../../src/common/constants/roles.js';
import { DEFAULT_PERMISSIONS } from '../../src/common/constants/permissions.js';
import { ROLE_PERMISSIONS } from './role-permissions.js';

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
   * 2. Seed Permissions
   */
  for (const permission of DEFAULT_PERMISSIONS) {
    await prisma.permission.upsert({
      where: { name: permission.name },
      update: { description: permission.description },
      create: permission,
    });
  }
  console.log('✅ Global Permissions seeded');

  /**
   * 3. Assign Role Permissions
   */
  for (const [roleName, permissionNames] of Object.entries(ROLE_PERMISSIONS)) {
    const role = await prisma.role.findUnique({ where: { name: roleName } });
    if (!role) continue;

    if (permissionNames.includes('*')) {
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
      continue;
    }

    for (const permName of permissionNames) {
      const perm = await prisma.permission.findUnique({ where: { name: permName } });
      if (!perm) continue;

      await prisma.rolePermission.upsert({
        where: {
          roleId_permissionId: { roleId: role.id, permissionId: perm.id },
        },
        update: {},
        create: { roleId: role.id, permissionId: perm.id },
      });
    }
  }
  console.log('✅ Role permissions mapped');

  /**
   * 4. Seed Super Admin & Regular Admin Accounts
   */
  const superAdminRole = await prisma.role.findUnique({ where: { name: AppRole.SUPER_ADMIN } });
  const userRole = await prisma.role.findUnique({ where: { name: AppRole.USER } });

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
    console.log(`✅ Super Admin created: ${adminUser.email}`);
  }

  // MODERATOR and SUPPORT are now valid platform roles — do NOT migrate them to USER.
  // If there are any genuinely stale custom roles (not in the enum), they can be cleaned up manually.

  console.log('🎉 Database seed completed successfully!');
}
