// src/common/interfaces/authenticated-request.interface.ts
import { Request } from 'express';
import { JwtPayload } from './jwt-payload.interface.js';

export interface AuthenticatedUser {
  sub: string;
  email: string;
  role: string;
  /** Resolved from DB by JwtStrategy */
  id: string;
}

export interface AuthenticatedRequest extends Request {
  user: AuthenticatedUser & JwtPayload;
}
