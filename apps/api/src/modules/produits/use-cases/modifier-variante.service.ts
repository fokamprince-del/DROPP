import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { ModifierVarianteDto } from '../dto/modifier-variante.dto.js';

@Injectable()
export class ModifierVarianteService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(
    produitId: string,
    varianteId: string,
    boutiqueId: string,
    dto: ModifierVarianteDto,
  ) {
    await this.verifierAppartenance(produitId, boutiqueId);

    return this.prisma.varianteProduit.update({
      where: { id: varianteId, produitId },
      data: {
        ...(dto.nom && { nom: dto.nom }),
        ...(dto.attributs && { attributs: dto.attributs }),
        ...(dto.prix !== undefined && { prix: dto.prix }),
        ...(dto.stockDisponible !== undefined && {
          stockDisponible: dto.stockDisponible,
        }),
      },
      select: {
        id: true,
        sku: true,
        nom: true,
        attributs: true,
        prix: true,
        stockDisponible: true,
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