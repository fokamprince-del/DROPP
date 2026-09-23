import {
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import type { Observable } from 'rxjs';

import { CLE_PUBLIC } from '../decorators/public.decorator.js';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private readonly reflector: Reflector) {
    super();
  }

  canActivate(
    context: ExecutionContext,
  ): boolean | Promise<boolean> | Observable<boolean> {
    const estPublic = this.reflector.getAllAndOverride<boolean>(CLE_PUBLIC, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (estPublic) return true;

    return super.canActivate(context);
  }

  handleRequest<T>(err: unknown, user: T): T {
    if (err || !user) {
      throw new UnauthorizedException('Authentification requise.');
    }
    return user;
  }
}
