import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import type { StatutCompte } from '@dropp/database';

const TRANSITIONS_AUTORISEES: Partial<Record<StatutCompte, StatutCompte[]>> = {
  ACTIF: ['SUSPENDU_TEMP', 'SUSPENDU_DEF'],
  SUSPENDU_TEMP: ['ACTIF', 'SUSPENDU_DEF'],
  EN_ATTENTE_VERIFICATION: ['SUSPENDU_TEMP', 'SUSPENDU_DEF'],
};

@Injectable()
export class SuspendreUtilisateurService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(
    utilisateurId: string,
    adminId: string,
    nouveauStatut: StatutCompte,
    raison: string,
  ) {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: { id: true, statutCompte: true },
    });

    if (!utilisateur) throw new NotFoundException('Utilisateur introuvable.');

    const transitionsPermises =
      TRANSITIONS_AUTORISEES[utilisateur.statutCompte] ?? [];

    if (!transitionsPermises.includes(nouveauStatut)) {
      throw new BadRequestException(
        `Transition ${utilisateur.statutCompte} → ${nouveauStatut} non autorisée.`,
      );
    }

    await this.prisma.$transaction([
      this.prisma.utilisateur.update({
        where: { id: utilisateurId },
        data: { statutCompte: nouveauStatut },
      }),
      // Révoquer toutes les sessions actives
      this.prisma.session.updateMany({
        where: { utilisateurId, dateRevocation: null },
        data: { dateRevocation: new Date() },
      }),
      this.prisma.journalAudit.create({
        data: {
          administrateurId: adminId,
          action: nouveauStatut === 'ACTIF'
            ? 'REACTIVER_UTILISATEUR'
            : 'SUSPENDRE_UTILISATEUR',
          resourceType: 'Utilisateur',
          resourceId: utilisateurId,
          details: { raison, ancienStatut: utilisateur.statutCompte, nouveauStatut },
        },
      }),
    ]);

    return { utilisateurId, statutCompte: nouveauStatut };
  }
}