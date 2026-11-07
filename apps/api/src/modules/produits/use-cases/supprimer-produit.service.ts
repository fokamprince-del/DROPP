import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

@Injectable()
export class SupprimerProduitService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Suppression définitive : seulement hors ligne et jamais commandé
   * (les lignes de commande référencent le produit). Sinon : archiver.
   */
  async executer(produitId: string, boutiqueId: string): Promise<void> {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: {
        boutiqueId: true,
        statut: true,
        _count: { select: { lignesCommande: true } },
      },
    });

    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId)
      throw new ForbiddenException('Accès refusé.');
    if (produit.statut === 'PUBLIE') {
      throw new BadRequestException(
        'Archivez le produit avant de le supprimer.',
      );
    }
    if (produit._count.lignesCommande > 0) {
      throw new ConflictException(
        'Ce produit a déjà été commandé : archivez-le plutôt que de le supprimer.',
      );
    }

    // Médias : détachés ici, fichiers effacés par le nettoyage périodique.
    await this.prisma.produit.delete({ where: { id: produitId } });
  }
}
