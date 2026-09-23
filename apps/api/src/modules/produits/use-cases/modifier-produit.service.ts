import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { ModifierProduitDto } from '../dto/modifier-produit.dto.js';

@Injectable()
export class ModifierProduitService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(produitId: string, boutiqueId: string, dto: ModifierProduitDto) {
    await this.verifierAppartenance(produitId, boutiqueId);

    if (dto.categorieId) {
      const cat = await this.prisma.categorie.findUnique({
        where: { id: dto.categorieId },
        select: { statut: true },
      });
      if (!cat || cat.statut !== 'ACTIVE') {
        throw new BadRequestException('Catégorie invalide ou inactive.');
      }
    }

    return this.prisma.produit.update({
      where: { id: produitId },
      data: {
        ...(dto.nom && { nom: dto.nom }),
        ...(dto.description && { description: dto.description }),
        ...(dto.categorieId && { categorieId: dto.categorieId }),
        ...(dto.prixBase !== undefined && { prixBase: dto.prixBase }),
        statut: 'BROUILLON',
      },
      select: {
        id: true,
        nom: true,
        statut: true,
        prixBase: true,
        boutiqueId: true,
        categorieId: true,
        dateCreation: true,
        dateModification: true,
      },
    });
  }

  private async verifierAppartenance(produitId: string, boutiqueId: string) {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: { boutiqueId: true },
    });
    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId) throw new ForbiddenException('Accès refusé.');
  }
}