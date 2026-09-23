import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

@Injectable()
export class DetailProduitService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(produitId: string, boutiqueId?: string) {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: {
        id: true,
        nom: true,
        description: true,
        statut: true,
        prixBase: true,
        boutiqueId: true,
        categorieId: true,
        dateCreation: true,
        dateModification: true,
        variantes: {
          select: {
            id: true,
            sku: true,
            nom: true,
            attributs: true,
            prix: true,
            stockDisponible: true,
          },
        },
        medias: {
          select: {
            id: true,
            ordre: true,
            media: {
              select: {
                id: true,
                typeMedia: true,
                cleStockage: true,
                typeMime: true,
                statutTraitement: true,
                largeur: true,
                hauteur: true,
              },
            },
          },
          orderBy: { ordre: 'asc' },
        },
      },
    });

    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (boutiqueId && produit.boutiqueId !== boutiqueId) {
      throw new ForbiddenException('Accès refusé.');
    }

    return produit;
  }
}