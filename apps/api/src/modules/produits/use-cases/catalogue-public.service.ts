import { Inject, Injectable } from '@nestjs/common';
import type { Prisma } from '@dropp/database';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../../infrastructure/stockage/stockage-provider.contract.js';
import { PrixService } from '../services/prix.service.js';

type Decimal = Prisma.Decimal;

/** Tris proposés dans l'onglet Marché. */
export const TRIS_CATALOGUE = {
  recents: 'recents',
  prix_croissant: 'prix_croissant',
  prix_decroissant: 'prix_decroissant',
  populaires: 'populaires',
} as const;
export type TriCatalogue = keyof typeof TRIS_CATALOGUE;

const ORDRE: Record<TriCatalogue, Prisma.ProduitOrderByWithRelationInput[]> = {
  recents: [{ dateCreation: 'desc' }],
  prix_croissant: [{ prixBase: 'asc' }, { dateCreation: 'desc' }],
  prix_decroissant: [{ prixBase: 'desc' }, { dateCreation: 'desc' }],
  populaires: [{ favoris: { _count: 'desc' } }, { dateCreation: 'desc' }],
};

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
    /** Recherche texte sur le nom et la description. */
    q?: string;
    /** Fourchette de prix en FCFA (prix de base ou d'au moins une variante). */
    prixMin?: number;
    prixMax?: number;
    tri?: TriCatalogue;
    /** Seulement les produits ayant au moins une variante en stock. */
    enStock?: boolean;
    page: number;
    limite: number;
    utilisateurId?: string;
  }) {
    const { categorieId, boutiqueId, q, page, limite, prixMin, prixMax, enStock } = params;

    // Une catégorie parente inclut ses sous-catégories (Mode → Robes, Chaussures…).
    const categories = categorieId ? await this.avecSousCategories(categorieId) : null;
    const fourchette =
      prixMin !== undefined || prixMax !== undefined
        ? { ...(prixMin !== undefined && { gte: prixMin }), ...(prixMax !== undefined && { lte: prixMax }) }
        : null;

    const where: Prisma.ProduitWhereInput = {
      statut: 'PUBLIE' as const,
      // Produits d'une boutique suspendue : invisibles.
      boutique: { statut: 'ACTIVE' },
      ...(categories && { categorieId: { in: categories } }),
      ...(enStock && { variantes: { some: { stockDisponible: { gt: 0 } } } }),
      AND: [
        ...(fourchette
          ? [
              {
                // Prix effectif d'une variante = son prix, sinon le prix de base.
                OR: [
                  { variantes: { some: { prix: fourchette } } },
                  { prixBase: fourchette, variantes: { some: { prix: null } } },
                ],
              },
            ]
          : []),
      ],
      ...(boutiqueId && { boutiqueId }),
      ...(q && {
        OR: [
          { nom: { contains: q, mode: 'insensitive' as const } },
          { description: { contains: q, mode: 'insensitive' as const } },
        ],
      }),
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
        orderBy: ORDRE[params.tri ?? 'recents'],
        skip: (page - 1) * limite,
        take: limite,
      }),
      this.prisma.produit.count({ where }),
    ]);

    let favorisSet: Set<string> = new Set();
    if (params.utilisateurId) {
      const ids = produits.map((p) => p.id);

      const favoris = await this.prisma.favoriProduit.findMany({
        where: { utilisateurId: params.utilisateurId, produitId: { in: ids } },
        select: { produitId: true },
      });
      favorisSet = new Set(favoris.map((f) => f.produitId));
    }

    return {
      donnees: produits.map((p) => ({
        id: p.id,
        nom: p.nom,
        prixMin: this.prixService.prixMin(p.prixBase, p.variantes),
        boutiqueId: p.boutiqueId,
        categorieId: p.categorieId,
        dateCreation: p.dateCreation,
        imagePrincipale: p.medias[0]?.media
          ? this.stockage.urlPublique(p.medias[0].media.cleStockage, {
              largeur: 400,
            })
          : null,
        enFavori: favorisSet.has(p.id),
      })),
      pagination: {
        total,
        page,
        limite,
        pages: Math.ceil(total / limite),
      },
    };
  }

  /** La catégorie et toutes ses descendantes actives (3 niveaux max). */
  private async avecSousCategories(categorieId: string): Promise<string[]> {
    const ids = [categorieId];
    let niveau = [categorieId];
    for (let p = 0; p < 3 && niveau.length; p++) {
      const enfants = await this.prisma.categorie.findMany({
        where: { parentId: { in: niveau }, statut: 'ACTIVE' },
        select: { id: true },
      });
      niveau = enfants.map((e) => e.id);
      ids.push(...niveau);
    }
    return ids;
  }
}
