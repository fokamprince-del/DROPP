import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import { SuppressionCompteService } from '../../../auth/use-cases/suppression-compte.service.js';
import { verifierCibleAdministrable } from '../../protection-admin.js';

@Injectable()
export class SupprimerUtilisateurService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly suppression: SuppressionCompteService,
  ) {}

  /**
   * Même anonymisation que la suppression demandée par l'utilisateur
   * (contraintes de la table respectées, fichiers personnels effacés).
   */
  async executer(utilisateurId: string, adminId: string, raison: string) {
    await verifierCibleAdministrable(this.prisma, adminId, utilisateurId);
    await this.suppression.anonymiser(utilisateurId, {
      administrateurId: adminId,
      raison,
    });
    return { message: 'Compte supprimé et anonymisé.' };
  }
}
