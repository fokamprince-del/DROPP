import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { PublicationAutoService } from '../services/publication-auto.service.js';
import type { CreerVarianteDto } from '../dto/creer-variante.dto.js';

@Injectable()
export class CreerVarianteService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly publicationAuto: PublicationAutoService,
  ) {}

  async executer(produitId: string, boutiqueId: string, dto: CreerVarianteDto) {
    await this.verifierAppartenance(produitId, boutiqueId);

    const skuExistant = await this.prisma.varianteProduit.findUnique({
      where: { sku: dto.sku },
      select: { id: true },
    });
    if (skuExistant) {
      throw new BadRequestException('Ce SKU est déjà utilisé.');
    }

    const variante = await this.prisma.varianteProduit.create({
      data: {
        produitId,
        sku: dto.sku,
        nom: dto.nom,
        attributs: dto.attributs,
        prix: dto.prix ?? null,
        stockDisponible: dto.stockDisponible,
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

    await this.publicationAuto.tenter(produitId);
    return variante;
  }

  private async verifierAppartenance(produitId: string, boutiqueId: string) {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: { boutiqueId: true },
    });
    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId)
      throw new ForbiddenException('Accès refusé.');
  }
}
