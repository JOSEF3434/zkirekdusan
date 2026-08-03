const fs = require('fs');

// users.service.spec.ts
let usersSvc = fs.readFileSync('src/modules/users/users.service.spec.ts', 'utf8');
usersSvc = usersSvc.replace(/import \{ PrismaService \} from '..\/..\/prisma\/prisma.service.js';/, "import { PrismaService } from '../../prisma/prisma.service.js';\nimport { UsersRepository } from './users.repository.js';");
usersSvc = usersSvc.replace(/providers: \[(.*?)\]/, "providers: [$1, { provide: UsersRepository, useValue: {} }]");
fs.writeFileSync('src/modules/users/users.service.spec.ts', usersSvc);

// auth.service.spec.ts
let authSvc = fs.readFileSync('src/modules/auth/auth.service.spec.ts', 'utf8');
authSvc = authSvc.replace(/import \{ AuthService \} from '.\/auth.service.js';/, "import { AuthService } from './auth.service.js';\nimport { UsersService } from '../users/users.service.js';\nimport { PasswordService } from './password.service.js';\nimport { JwtService } from '@nestjs/jwt';\nimport { ConfigService } from '@nestjs/config';");
authSvc = authSvc.replace(/providers: \[(.*?)\]/, "providers: [AuthService, { provide: UsersService, useValue: {} }, { provide: PasswordService, useValue: {} }, { provide: JwtService, useValue: {} }, { provide: ConfigService, useValue: {} }]");
fs.writeFileSync('src/modules/auth/auth.service.spec.ts', authSvc);
