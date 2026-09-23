import { Inject, Injectable } from '@nestjs/common';
import type { Prisma } from '../../../generated/prisma/client.js';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../../infrastructure/stockage/stockage-provider.contract.js';
import { PrixService } from '../services/prix.service.js';

type Decimal = Prisma.Decimal;

@Injectable()
export class CataloguePublicService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly prixService: PrixService,
    @Inject(STOCKAGE_PROVIDER)
    private readonly stockage: StockageProvider,
  ) {}

  async executer(params: {
    categorieId?: string;
    boutiqueId?: string;
    page: number;
    limite: number;
  }) {
    const { categorieId, boutiqueId, page, limite } = params;

    const where = {
      statut: 'PUBLIE' as const,
      ...(categorieId && { categorieId }),
      ...(boutiqueId && { boutiqueId }),
    };

    const [produits, total] = await this.prisma.$transaction([
      this.prisma.produit.findMany({
        where,
        select: {
          id: true,
          nom: true,
          prixBase: true,
          boutiqueId: true,
          categorieId: true,
          dateCreation: true,
          medias: {
            where: { ordre: 0 },
            select: {
              media: { select: { cleStockage: true, typeMedia: true } },
            },
            take: 1,
          },
          variantes: {
            select: { prix: true, stockDisponible: true },
          },
        },
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
      }),
      this.prisma.produit.count({ where }),
    ]);

    return {
      donnees: produits.map((p) => ({
        id: p.id,
        nom: p.nom,
        prixMin: this.prixService.prixMin(p.prixBase, p.variantes),
        boutiqueId: p.boutiqueId,
        categorieId: p.categorieId,
        dateCreation: p.dateCreation,
        imagePrincipale: p.medias[0]?.media
          ? this.stockage.urlPublique(p.medias[0].media.cleStockage, { largeur: 400 })
          : null,
      })),
      pagination: {
        total,
        page,
        limite,
        pages: Math.ceil(total / limite),
      },
    };
  }
}