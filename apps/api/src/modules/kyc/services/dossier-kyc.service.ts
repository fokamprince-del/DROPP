import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';

import type { StatutKyc } from '@dropp/database';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

/** Statuts dans lesquels le vendeur peut encore compléter son dossier. */
export const STATUTS_MODIFIABLES: StatutKyc[] = ['EN_ATTENTE', 'REJETE'];

@Injectable()
export class DossierKycService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Dossier en cours du vendeur. Créé s'il n'existe pas encore (vendeurs
   * inscrits avant la création automatique du dossier à /sellers/devenir).
   */
  async courant(vendeurId: string) {
    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: vendeurId },
      select: {
        dossiersKyc: {
          orderBy: { dateSoumission: 'desc' },
          take: 1,
          select: { id: true, statut: true },
        },
      },
    });
    if (!vendeur) throw new ForbiddenException('Profil vendeur introuvable.');

    return (
      vendeur.dossiersKyc[0] ??
      this.prisma.dossierKyc.create({
        data: { vendeurId },
        select: { id: true, statut: true },
      })
    );
  }

  /** Dossier en cours, à condition qu'il soit encore modifiable. */
  async modifiable(vendeurId: string) {
    const dossier = await this.courant(vendeurId);
    if (!STATUTS_MODIFIABLES.includes(dossier.statut)) {
      throw new BadRequestException(
        dossier.statut === 'VALIDE'
          ? 'Votre identité est déjà vérifiée.'
          : 'Votre dossier est en cours d’examen : il ne peut plus être modifié.',
      );
    }
    return dossier;
  }
}
