const fs = require('fs');

const files = [
  'src/modules/users/users.service.spec.ts',
  'src/modules/roles/roles.service.spec.ts',
  'src/modules/sessions/sessions.service.spec.ts',
  'src/modules/refresh-token/refresh-token.service.spec.ts',
  'src/modules/authorization/authorization.service.spec.ts'
];

for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  content = content.replace(/import \{ Test, TestingModule \} from '@nestjs\/testing';/, "import { Test, TestingModule } from '@nestjs/testing';\nimport { PrismaService } from '../../prisma/prisma.service.js';");
  content = content.replace(/providers: \[(.*?)\]/, "providers: [$1, { provide: PrismaService, useValue: {} }]");
  fs.writeFileSync(file, content);
}

// auth.controller.spec.ts
let authCtrl = fs.readFileSync('src/modules/auth/auth.controller.spec.ts', 'utf8');
authCtrl = authCtrl.replace(/import \{ Test, TestingModule \} from '@nestjs\/testing';/, "import { Test, TestingModule } from '@nestjs/testing';\nimport { AuthService } from './auth.service.js';");
authCtrl = authCtrl.replace(/controllers: \[(.*?)\]/, "controllers: [$1],\n      providers: [{ provide: AuthService, useValue: {} }]");
fs.writeFileSync('src/modules/auth/auth.controller.spec.ts', authCtrl);

// auth.service.spec.ts
let authSvc = fs.readFileSync('src/modules/auth/auth.service.spec.ts', 'utf8');
authSvc = authSvc.replace(/providers: \[(.*?)\]/, "providers: [$1, { provide: 'UsersService', useValue: {} }, { provide: 'PasswordService', useValue: {} }, { provide: 'JwtService', useValue: {} }, { provide: 'ConfigService', useValue: {} }]");
fs.writeFileSync('src/modules/auth/auth.service.spec.ts', authSvc);
