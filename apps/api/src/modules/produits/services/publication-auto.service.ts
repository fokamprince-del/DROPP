import { Injectable } from '@nestjs/common';
import  { Prisma } from '../../../generated/prisma/client.js';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

type Decimal = Prisma.Decimal;

type ProduitPourValidation = {
  statut: string;
  nom: string;
  description: string | null;
  categorieId: string;
  prixBase: Decimal;
  variantes: Array<{ prix: Decimal | null; stockDisponible: number }>;
  medias: Array<{ media: { statutTraitement: string } }>;
};

@Injectable()
export class PublicationAutoService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Publie automatiquement le produit si toutes les conditions sont remplies.
   * Appelé après chaque ajout de variante ou confirmation de média.
   * Sans effet si le produit est déjà PUBLIE ou ARCHIVE.
   */
  async tenter(produitId: string): Promise<void> {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: {
        statut: true,
        nom: true,
        description: true,
        categorieId: true,
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

    if (
      !produit ||
      produit.statut === 'PUBLIE' ||
      produit.statut === 'ARCHIVE'
    ) {
      return;
    }

    if (this.conditionsRemplies(produit)) {
      await this.prisma.produit.update({
        where: { id: produitId },
        data: { statut: 'PUBLIE' },
      });
    }
  }

  private conditionsRemplies(produit: ProduitPourValidation): boolean {
    const aDescription =
      typeof produit.description === 'string' &&
      produit.description.trim().length >= 10;

    const aVarianteValide = produit.variantes.some(
      (v) =>
        (v.prix ?? produit.prixBase).gt(new Prisma.Decimal(0)) &&
        v.stockDisponible >= 0,
    );

    const aMediaPret = produit.medias.some(
      (m) => m.media.statutTraitement === 'PRET',
    );

    return aDescription && aVarianteValide && aMediaPret;
  }
}