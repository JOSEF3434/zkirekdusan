import { PrismaClient } from '@prisma/client';
import { DEFAULT_ROLES } from '../../src/common/constants/roles.js';
import { DEFAULT_PERMISSIONS } from '../../src/common/constants/permissions.js';
import { ROLE_PERMISSIONS } from './role-permissions.js';

export async function seed(prisma: PrismaClient) {
  console.log('🌱 Starting database seed...');

  /**
   * Seed Roles
   */
  for (const role of DEFAULT_ROLES) {
    await prisma.role.upsert({
      where: {
        name: role.name,
      },
      update: {},
      create: role,
    });
  }

  console.log('✅ Roles seeded');

  /**
   * Seed Permissions
   */
  for (const permission of DEFAULT_PERMISSIONS) {
    await prisma.permission.upsert({
      where: {
        name: permission.name,
      },
      update: {},
      create: permission,
    });
  }

  console.log('✅ Permissions seeded');

  /**
   * Assign Permissions to Roles
   */
  for (const [roleName, permissionNames] of Object.entries(ROLE_PERMISSIONS)) {
    const role = await prisma.role.findUnique({
      where: {
        name: roleName,
      },
    });

    if (!role) continue;

    // SUPER_ADMIN gets every permission
    if (permissionNames.includes('*')) {
      const allPermissions = await prisma.permission.findMany();

      for (const permission of allPermissions) {
        await prisma.rolePermission.upsert({
          where: {
            roleId_permissionId: {
              roleId: role.id,
              permissionId: permission.id,
            },
          },
          update: {},
          create: {
            roleId: role.id,
            permissionId: permission.id,
          },
        });
      }

      continue;
    }

    for (const permissionName of permissionNames) {
      const permission = await prisma.permission.findUnique({
        where: {
          name: permissionName,
        },
      });

      if (!permission) continue;

      await prisma.rolePermission.upsert({
        where: {
          roleId_permissionId: {
            roleId: role.id,
            permissionId: permission.id,
          },
        },
        update: {},
        create: {
          roleId: role.id,
          permissionId: permission.id,
        },
      });
    }
  }

  console.log('✅ Role permissions assigned');

  console.log('🎉 Database seed completed successfully!');
}
