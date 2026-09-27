import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { UtilisateurConnecte } from '../types/utilisateur-connecte.js';
import { CLE_PROFIL_CLIENT } from '../decorators/profil-client.decorator.js';

@Injectable()
export class ProfilClientGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requis = this.reflector.getAllAndOverride<boolean>(
      CLE_PROFIL_CLIENT,
      [context.getHandler(), context.getClass()],
    );

    if (!requis) return true;

    const request = context.switchToHttp().getRequest<Request>();
    const utilisateur = request.user as UtilisateurConnecte | undefined;

    if (!utilisateur) {
      throw new ForbiddenException('Profil client requis.');
    }

    const client = await this.prisma.client.findUnique({
      where: { id: utilisateur.id },
      select: { statutClient: true },
    });

    if (!client || client.statutClient !== 'ACTIF') {
      throw new ForbiddenException('Profil client requis.');
    }

    return true;
  }
}
