import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';

import type { StatutVendeur } from '@dropp/database';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { CLE_PROFIL_VENDEUR } from '../decorators/profil-vendeur.decorator.js';
import type { UtilisateurConnecte } from '../types/utilisateur-connecte.js';

@Injectable()
export class ProfilVendeurGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const statuts = this.reflector.getAllAndOverride<StatutVendeur[] | undefined>(
      CLE_PROFIL_VENDEUR,
      [context.getHandler(), context.getClass()],
    );
    if (!statuts) return true;

    const utilisateur = context.switchToHttp().getRequest<Request>().user as
      | UtilisateurConnecte
      | undefined;
    if (!utilisateur) {
      throw new ForbiddenException('Profil vendeur requis.');
    }

    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: utilisateur.id },
      select: { statutVendeur: true },
    });
    if (!vendeur || !statuts.includes(vendeur.statutVendeur)) {
      throw new ForbiddenException(
        statuts.length === 1 && statuts[0] === 'ACTIF'
          ? 'Profil vendeur actif requis.'
          : 'Profil vendeur requis.',
      );
    }
    return true;
  }
}
