import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { ROLES_KEY } from '../decorators/roles.decorator.js';
import type { UtilisateurConnecte } from '../types/utilisateur-connecte.js';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const rolesRequis = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!rolesRequis?.length) {
      return true;
    }

    const requete = context
      .switchToHttp()
      .getRequest<Request & { user?: UtilisateurConnecte }>();

    if (!requete.user) {
      throw new ForbiddenException('Authentification requise.');
    }

    const attribution = await this.prisma.utilisateurRole.findFirst({
      where: {
        utilisateurId: requete.user.id,
        role: { nom: { in: rolesRequis } },
      },
      select: { roleId: true },
    });

    if (!attribution) {
      throw new ForbiddenException('Droits insuffisants.');
    }

    return true;
  }
}
