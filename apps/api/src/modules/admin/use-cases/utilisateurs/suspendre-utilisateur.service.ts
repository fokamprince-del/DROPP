import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import type { StatutCompte } from '@dropp/database';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import { RevocationService } from '../../../../infrastructure/revocation/revocation.service.js';
import { verifierCibleAdministrable } from '../../protection-admin.js';

const TRANSITIONS_AUTORISEES: Partial<Record<StatutCompte, StatutCompte[]>> = {
  ACTIF: ['SUSPENDU_TEMP', 'SUSPENDU_DEF'],
  SUSPENDU_TEMP: ['ACTIF', 'SUSPENDU_DEF'],
  EN_ATTENTE_VERIFICATION: ['SUSPENDU_TEMP', 'SUSPENDU_DEF'],
};

@Injectable()
export class SuspendreUtilisateurService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly revocation: RevocationService,
  ) {}

  /**
   * Suspension : sessions révoquées et jetons invalidés immédiatement.
   * Ses contenus (boutique, publications…) disparaissent du public tant que
   * le compte n'est pas ACTIF (voir BOUTIQUE_VISIBLE).
   */
  async executer(
    utilisateurId: string,
    adminId: string,
    nouveauStatut: StatutCompte,
    raison: string,
  ) {
    await verifierCibleAdministrable(this.prisma, adminId, utilisateurId);

    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: { statutCompte: true, telephoneVerifieLe: true },
    });
    if (!utilisateur) throw new NotFoundException('Utilisateur introuvable.');

    const transitionsPermises =
      TRANSITIONS_AUTORISEES[utilisateur.statutCompte] ?? [];
    if (!transitionsPermises.includes(nouveauStatut)) {
      throw new BadRequestException(
        `Transition ${utilisateur.statutCompte} → ${nouveauStatut} non autorisée.`,
      );
    }
    // Un compte ACTIF exige un téléphone vérifié (contrainte en base).
    if (nouveauStatut === 'ACTIF' && !utilisateur.telephoneVerifieLe) {
      throw new BadRequestException(
        'Téléphone jamais vérifié : le compte ne peut pas être réactivé.',
      );
    }

    await this.prisma.$transaction([
      this.prisma.utilisateur.update({
        where: { id: utilisateurId },
        data: { statutCompte: nouveauStatut },
      }),
      this.prisma.session.updateMany({
        where: { utilisateurId, dateRevocation: null },
        data: { dateRevocation: new Date() },
      }),
      this.prisma.journalAudit.create({
        data: {
          administrateurId: adminId,
          action:
            nouveauStatut === 'ACTIF'
              ? 'REACTIVER_UTILISATEUR'
              : 'SUSPENDRE_UTILISATEUR',
          resourceType: 'Utilisateur',
          resourceId: utilisateurId,
          details: { raison, ancienStatut: utilisateur.statutCompte, nouveauStatut },
        },
      }),
    ]);
    await this.revocation.revoquerUtilisateur(utilisateurId);

    return { utilisateurId, statutCompte: nouveauStatut };
  }
}
