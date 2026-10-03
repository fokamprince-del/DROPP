import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import type { StatutVendeur } from '@dropp/database';

@Injectable()
export class SuspendreVendeurService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(
    vendeurId: string,
    adminId: string,
    nouveauStatut: StatutVendeur,
    raison: string,
  ) {
    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: vendeurId },
      select: { id: true, statutVendeur: true },
    });

    if (!vendeur) throw new NotFoundException('Vendeur introuvable.');

    if (vendeur.statutVendeur === nouveauStatut) {
      throw new BadRequestException('Le vendeur a déjà ce statut.');
    }

    await this.prisma.$transaction([
      this.prisma.vendeur.update({
        where: { id: vendeurId },
        data: { statutVendeur: nouveauStatut },
      }),
      this.prisma.journalAudit.create({
        data: {
          administrateurId: adminId,
          action: nouveauStatut === 'ACTIF'
            ? 'REACTIVER_VENDEUR'
            : 'SUSPENDRE_VENDEUR',
          resourceType: 'Vendeur',
          resourceId: vendeurId,
          details: { raison, ancienStatut: vendeur.statutVendeur, nouveauStatut },
        },
      }),
    ]);

    return { vendeurId, statutVendeur: nouveauStatut };
  }
}