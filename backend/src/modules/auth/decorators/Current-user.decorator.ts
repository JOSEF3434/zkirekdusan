// backend/src/modules/auth/decorators/Current-user.decorator.ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const CurrentUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest<{ user?: unknown }>();
    return request.user;
  },
);
export interface JwtPayload {
  sub: string;

  id: string;

  email: string;

  role: string;
}
