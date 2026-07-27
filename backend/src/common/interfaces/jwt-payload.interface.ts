// src/common/interfaces/jwt-payload.interface.ts
// Single source of truth for JWT payload shape — imported everywhere

export interface JwtPayload {
  /** User UUID — used as Prisma `where: { id }` */
  sub: string;

  email: string;

  /** Global role name: SUPER_ADMIN | ADMIN | USER */
  role: string;

  /** JWT standard issued-at */
  iat?: number;

  /** JWT standard expires-at */
  exp?: number;
}

export interface RefreshTokenPayload {
  sub: string;
  iat?: number;
  exp?: number;
}
