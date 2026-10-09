import { Injectable } from '@nestjs/common';
import { Prisma } from '@dropp/database';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

type Decimal = Prisma.Decimal;

type ProduitPourValidation = {
  description: string | null;
  prixBase: Decimal;
  variantes: Array<{ prix: Decimal | null; stockDisponible: number }>;
  medias: Array<{ media: { statutTraitement: string } }>;
};

/** Statuts gérés automatiquement ; ARCHIVE et REJETE ne sont jamais touchés. */
const STATUTS_AUTOMATIQUES = new Set(['BROUILLON', 'PROCESSING', 'PUBLIE']);

@Injectable()
export class PublicationAutoService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Met le statut du produit en cohérence avec son contenu, après chaque
   * modification (produit, variante, média) :
   * - brouillon complet → PUBLIE ;
   * - publié devenu incomplet (plus de média, prix nul…) → BROUILLON.
   * Sans effet sur un produit ARCHIVE (choix du vendeur) ou REJETE (modération).
   */
  async tenter(produitId: string): Promise<void> {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: {
        statut: true,
        description: true,
        prixBase: true,
        variantes: {
          select: { prix: true, stockDisponible: true },
        },
        medias: {
          select: {
            media: { select: { statutTraitement: true } },
          },
        },
      },
    });
    if (!produit || !STATUTS_AUTOMATIQUES.has(produit.statut)) return;

    const cible = this.conditionsRemplies(produit) ? 'PUBLIE' : 'BROUILLON';
    if (cible !== produit.statut) {
      await this.prisma.produit.updateMany({
        where: { id: produitId, statut: produit.statut },
        data: { statut: cible },
      });
    }
  }

  private conditionsRemplies(produit: ProduitPourValidation): boolean {
    const aDescription =
      typeof produit.description === 'string' &&
      produit.description.trim().length >= 10;

    const aVarianteValide = produit.variantes.some((v) =>
      (v.prix ?? produit.prixBase).gt(new Prisma.Decimal(0)),
    );

    const aMediaPret = produit.medias.some(
      (m) => m.media.statutTraitement === 'PRET',
    );

    return aDescription && aVarianteValide && aMediaPret;
  }
}
