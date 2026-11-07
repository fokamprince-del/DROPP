import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import type { StatutVendeur } from '@dropp/database';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import { verifierCibleAdministrable } from '../../protection-admin.js';

@Injectable()
export class SuspendreVendeurService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * SUSPENDU : la boutique et ses contenus disparaissent du public
   * (BOUTIQUE_VISIBLE) et le vendeur perd l'accès aux routes vendeur.
   * Levée de suspension : ACTIF seulement si son identité a été validée,
   * sinon retour à EN_ATTENTE_VALIDATION (le KYC ne peut pas être contourné).
   */
  async executer(
    vendeurId: string,
    adminId: string,
    nouveauStatut: Extract<StatutVendeur, 'ACTIF' | 'SUSPENDU'>,
    raison: string,
  ) {
    await verifierCibleAdministrable(this.prisma, adminId, vendeurId);

    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: vendeurId },
      select: {
        statutVendeur: true,
        dossiersKyc: { where: { statut: 'VALIDE' }, select: { id: true }, take: 1 },
      },
    });
    if (!vendeur) throw new NotFoundException('Vendeur introuvable.');

    let statutFinal: StatutVendeur = nouveauStatut;
    if (nouveauStatut === 'ACTIF') {
      if (vendeur.statutVendeur !== 'SUSPENDU') {
        throw new BadRequestException(
          'Seul un vendeur suspendu peut être réactivé. La validation passe par le KYC.',
        );
      }
      if (vendeur.dossiersKyc.length === 0) statutFinal = 'EN_ATTENTE_VALIDATION';
    } else if (vendeur.statutVendeur === 'SUSPENDU') {
      throw new BadRequestException('Le vendeur est déjà suspendu.');
    }

    await this.prisma.$transaction([
      this.prisma.vendeur.update({
        where: { id: vendeurId },
        data: { statutVendeur: statutFinal },
      }),
      this.prisma.journalAudit.create({
        data: {
          administrateurId: adminId,
          action:
            nouveauStatut === 'ACTIF' ? 'REACTIVER_VENDEUR' : 'SUSPENDRE_VENDEUR',
          resourceType: 'Vendeur',
          resourceId: vendeurId,
          details: { raison, ancienStatut: vendeur.statutVendeur, nouveauStatut: statutFinal },
        },
      }),
    ]);

    return { vendeurId, statutVendeur: statutFinal };
  }
}
