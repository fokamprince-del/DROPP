import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

@Injectable()
export class ListerProduitsBoutiqueService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(boutiqueId: string) {
    return this.prisma.produit.findMany({
      where: { boutiqueId },
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
      orderBy: { dateCreation: 'desc' },
    });
  }
}
