import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

@Injectable()
export class SupprimerProduitService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(produitId: string, boutiqueId: string): Promise<void> {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: { boutiqueId: true, statut: true },
    });

    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId)
      throw new ForbiddenException('Accès refusé.');
    if (produit.statut === 'PUBLIE') {
      throw new BadRequestException(
        'Archivez le produit avant de le supprimer.',
      );
    }

    await this.prisma.produit.delete({ where: { id: produitId } });
  }
}
