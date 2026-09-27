import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { CLE_PROFIL_VENDEUR } from '../decorators/profil-vendeur.decorator.js';
import { UtilisateurConnecte } from '../types/utilisateur-connecte.js';

@Injectable()
export class ProfilVendeurGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requis = this.reflector.getAllAndOverride<boolean>(
      CLE_PROFIL_VENDEUR,
      [context.getHandler(), context.getClass()],
    );

    if (!requis) return true;

    const request = context.switchToHttp().getRequest<Request>();
    const utilisateur = request.user as UtilisateurConnecte | undefined;

    if (!utilisateur) {
      throw new ForbiddenException('Profil vendeur actif requis.');
    }

    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: utilisateur.id },
      select: { statutVendeur: true },
    });

    if (!vendeur || vendeur.statutVendeur !== 'ACTIF') {
      throw new ForbiddenException('Profil vendeur actif requis.');
    }

    return true;
  }
}
