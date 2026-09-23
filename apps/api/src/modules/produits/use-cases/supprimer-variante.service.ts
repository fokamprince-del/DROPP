import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

@Injectable()
export class SupprimerVarianteService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(produitId: string, varianteId: string, boutiqueId: string): Promise<void> {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: { boutiqueId: true },
    });
    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId) throw new ForbiddenException('Accès refusé.');

    const variante = await this.prisma.varianteProduit.findUnique({
      where: { id: varianteId, produitId },
      select: { id: true },
    });
    if (!variante) throw new NotFoundException('Variante introuvable.');

    await this.prisma.varianteProduit.delete({ where: { id: varianteId } });
  }
}