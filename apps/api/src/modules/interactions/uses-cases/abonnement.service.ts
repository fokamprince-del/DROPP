import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

@Injectable()
export class AbonnementService {
  constructor(private readonly prisma: PrismaService) {}

  async suivre(utilisateurId: string, vendeurId: string) {
    if (utilisateurId === vendeurId) {
      throw new BadRequestException('Impossible de se suivre soi-même.');
    }

    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: vendeurId },
      select: { statutVendeur: true },
    });

    if (!vendeur || vendeur.statutVendeur !== 'ACTIF') {
      throw new NotFoundException('Vendeur introuvable.');
    }

    try {
      await this.prisma.abonnement.create({
        data: { utilisateurId, vendeurId, statut: 'ACTIF' },
      });
    } catch (e: unknown) {
      if (this.estViolationUnicite(e)) {
        throw new ConflictException('Vous suivez déjà ce vendeur.');
      }
      throw e;
    }

    const totalAbonnes = await this.prisma.abonnement.count({
      where: { vendeurId, statut: 'ACTIF' },
    });

    return { vendeurId, abonnes: totalAbonnes };
  }

  private estViolationUnicite(e: unknown): boolean {
    return (
      typeof e === 'object' &&
      e !== null &&
      'code' in e &&
      (e as { code: string }).code === 'P2002'
    );
  }

  async nePlusSuivre(utilisateurId: string, vendeurId: string) {
    const abonnement = await this.prisma.abonnement.findUnique({
      where: {
        utilisateurId_vendeurId: { utilisateurId, vendeurId },
      },
      select: { id: true },
    });

    if (!abonnement) throw new NotFoundException('Abonnement introuvable.');

    await this.prisma.abonnement.delete({
      where: {
        utilisateurId_vendeurId: { utilisateurId, vendeurId },
      },
    });

    const totalAbonnes = await this.prisma.abonnement.count({
      where: { vendeurId, statut: 'ACTIF' },
    });

    return { vendeurId, abonnes: totalAbonnes };
  }
}
