import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  handleRequest(
    _err: any,
    user: any,
    _info: any,
    _context: any,
    _status?: any,
  ) {
    // Return the user if authenticated, otherwise return undefined (do not throw error)
    return user;
  }
}
