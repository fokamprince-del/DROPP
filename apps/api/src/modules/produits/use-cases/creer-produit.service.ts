import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { CreerProduitDto } from '../dto/creer-produit.dto.js';

@Injectable()
export class CreerProduitService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(boutiqueId: string, dto: CreerProduitDto) {
    await this.verifierCategorie(dto.categorieId);

    return this.prisma.produit.create({
      data: {
        boutiqueId,
        categorieId: dto.categorieId,
        nom: dto.nom,
        description: dto.description,
        prixBase: dto.prixBase,
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

  private async verifierCategorie(categorieId: string): Promise<void> {
    const cat = await this.prisma.categorie.findUnique({
      where: { id: categorieId },
      select: { statut: true },
    });
    if (!cat || cat.statut !== 'ACTIVE') {
      throw new BadRequestException('Catégorie invalide ou inactive.');
    }
  }
}
