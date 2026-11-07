import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { PublicationAutoService } from '../services/publication-auto.service.js';

@Injectable()
export class SupprimerVarianteService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly publicationAuto: PublicationAutoService,
  ) {}

  async executer(
    produitId: string,
    varianteId: string,
    boutiqueId: string,
  ): Promise<void> {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: { boutiqueId: true },
    });
    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId)
      throw new ForbiddenException('Accès refusé.');

    const variante = await this.prisma.varianteProduit.findUnique({
      where: { id: varianteId, produitId },
      select: {
        _count: { select: { lignesCommande: true, reservations: true } },
      },
    });
    if (!variante) throw new NotFoundException('Variante introuvable.');
    if (variante._count.lignesCommande > 0 || variante._count.reservations > 0) {
      throw new ConflictException(
        'Cette variante a déjà été commandée : mettez son stock à 0 plutôt que de la supprimer.',
      );
    }

    await this.prisma.$transaction([
      this.prisma.articlePanier.deleteMany({ where: { varianteProduitId: varianteId } }),
      this.prisma.varianteProduit.delete({ where: { id: varianteId } }),
    ]);
    await this.publicationAuto.tenter(produitId);
  }
}
