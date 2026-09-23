import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { UtilisateurConnecte } from '../types/utilisateur-connecte.js';

export const CLE_ROLES_ADMIN = 'roles_admin_requis';

export const RequiertRoleAdmin = (...roles: string[]) =>
  SetMetadata(CLE_ROLES_ADMIN, roles);

@Injectable()
export class RoleAdminGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const rolesRequis = this.reflector.getAllAndOverride<string[]>(
      CLE_ROLES_ADMIN,
      [context.getHandler(), context.getClass()],
    );

    if (!rolesRequis || rolesRequis.length === 0) return true;

    const request = context.switchToHttp().getRequest<Request>();
    const utilisateur = request.user as UtilisateurConnecte | undefined;

    if (!utilisateur) {
      throw new ForbiddenException('Accès réservé aux administrateurs.');
    }

    // Relecture en base : un rôle retiré prend effet immédiatement
    const rolesTrouves = await this.prisma.utilisateurRole.findMany({
      where: rolesRequis.length === 0 ?
        { utilisateurId: utilisateur.id }:{
            utilisateurId: utilisateur.id,
            role: { nom: { in: rolesRequis } },
        },
      select: { role: { select: { nom: true } } },
    });

    if (rolesTrouves.length === 0) {
      throw new ForbiddenException('Accès réservé aux administrateurs.');
    }

    return true;
  }

  
}