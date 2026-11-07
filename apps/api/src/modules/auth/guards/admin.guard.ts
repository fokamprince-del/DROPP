import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { CLE_ROLES_ADMIN } from '../decorators/role-admin.decorator.js';
import type { UtilisateurConnecte } from '../types/utilisateur-connecte.js';

/**
 * Exige au moins un des rôles posés par @Admin(...).
 * Refus par défaut : sans rôle déclaré, personne ne passe.
 * Relit la base : un rôle retiré prend effet immédiatement.
 */
@Injectable()
export class RoleAdminGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const rolesRequis = this.reflector.getAllAndOverride<string[] | undefined>(
      CLE_ROLES_ADMIN,
      [context.getHandler(), context.getClass()],
    );
    const utilisateur = context.switchToHttp().getRequest<Request>().user as
      | UtilisateurConnecte
      | undefined;

    if (!rolesRequis?.length || !utilisateur) {
      throw new ForbiddenException('Accès réservé aux administrateurs.');
    }

    const attribution = await this.prisma.utilisateurRole.findFirst({
      where: {
        utilisateurId: utilisateur.id,
        role: { nom: { in: rolesRequis } },
      },
      select: { roleId: true },
    });
    if (!attribution) {
      throw new ForbiddenException('Accès réservé aux administrateurs.');
    }
    return true;
  }
}
