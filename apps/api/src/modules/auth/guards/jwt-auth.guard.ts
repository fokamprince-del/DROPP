import {
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import type { Request } from 'express';

import { CLE_PUBLIC } from '../decorators/public.decorator.js';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private readonly reflector: Reflector) {
    super();
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (!this.estPublic(context)) {
      return (await super.canActivate(context)) as boolean;
    }

    // Route publique : authentification optionnelle. Si un token valide est
    // fourni, request.user est renseigné (états « aimé », « favori »,
    // « abonné »…) ; sinon la requête passe en anonyme.
    const requete = context.switchToHttp().getRequest<Request>();
    if (requete.headers.authorization) {
      try {
        await super.canActivate(context);
      } catch {
        // token absent/expiré : accès anonyme
      }
    }
    return true;
  }

  handleRequest<T>(
    err: unknown,
    user: T,
    _info: unknown,
    context: ExecutionContext,
  ): T {
    if (err || !user) {
      if (this.estPublic(context)) return undefined as T;
      throw new UnauthorizedException('Authentification requise.');
    }
    return user;
  }

  private estPublic(context: ExecutionContext): boolean {
    return (
      this.reflector.getAllAndOverride<boolean>(CLE_PUBLIC, [
        context.getHandler(),
        context.getClass(),
      ]) ?? false
    );
  }
}
