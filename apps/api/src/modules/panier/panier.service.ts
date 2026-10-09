import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { Prisma } from '@dropp/database';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { BOUTIQUE_VISIBLE } from '../shops/boutique-visible.js';
import type { AjouterArticlePanierDto } from './dto/ajouter-article-panier.dto.js';

export const QUANTITE_MAX_ARTICLE = 1_000;

const panierSelect = {
  id: true,
  statut: true,
  dateModification: true,
  articles: {
    orderBy: { dateAjout: 'asc' as const },
    select: {
      id: true,
      varianteProduitId: true,
      quantite: true,
      prixUnitaire: true,
      varianteProduit: {
        select: {
          id: true,
          sku: true,
          nom: true,
          attributs: true,
          stockDisponible: true,
          prix: true,
          produit: {
            select: {
              id: true,
              nom: true,
              prixBase: true,
              boutiqueId: true,
              statut: true,
              boutique: {
                select: {
                  nom: true,
                  statut: true,
                  vendeur: {
                    select: {
                      statutVendeur: true,
                      utilisateur: { select: { statutCompte: true } },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
} satisfies Prisma.PanierSelect;

type PanierBrut = Prisma.PanierGetPayload<{ select: typeof panierSelect }>;

@Injectable()
export class PanierService {
  constructor(private readonly prisma: PrismaService) {}

  async obtenir(utilisateurId: string) {
    const panier = await this.prisma.panier.findFirst({
      where: { utilisateurId, statut: 'ACTIF' },
      select: panierSelect,
    });
    return this.formater(panier);
  }

  async ajouter(utilisateurId: string, dto: AjouterArticlePanierDto) {
    const variante = await this.prisma.varianteProduit.findFirst({
      where: {
        id: dto.varianteProduitId,
        produit: { statut: 'PUBLIE', boutique: BOUTIQUE_VISIBLE },
      },
      select: {
        prix: true,
        stockDisponible: true,
        produit: { select: { prixBase: true, boutiqueId: true } },
      },
    });
    if (!variante) throw new NotFoundException('Variante introuvable.');
    if (variante.produit.boutiqueId === utilisateurId) {
      throw new BadRequestException(
        'Vous ne pouvez pas ajouter vos propres produits au panier.',
      );
    }

    const panier = await this.panierActif(utilisateurId);
    const articleExistant = await this.prisma.articlePanier.findUnique({
      where: {
        panierId_varianteProduitId: {
          panierId: panier.id,
          varianteProduitId: dto.varianteProduitId,
        },
      },
      select: { quantite: true },
    });
    const quantite = (articleExistant?.quantite ?? 0) + dto.quantite;
    if (quantite > QUANTITE_MAX_ARTICLE)
      throw new BadRequestException('Quantité maximale dépassée.');
    if (quantite > variante.stockDisponible)
      throw new BadRequestException(
        `Stock insuffisant : ${variante.stockDisponible} disponible(s).`,
      );

    const prixUnitaire = variante.prix ?? variante.produit.prixBase;
    await this.prisma.articlePanier.upsert({
      where: {
        panierId_varianteProduitId: {
          panierId: panier.id,
          varianteProduitId: dto.varianteProduitId,
        },
      },
      create: {
        panierId: panier.id,
        varianteProduitId: dto.varianteProduitId,
        quantite: dto.quantite,
        prixUnitaire,
      },
      update: { quantite: { increment: dto.quantite }, prixUnitaire },
    });
    await this.toucher(panier.id);
    return this.obtenir(utilisateurId);
  }

  async modifier(utilisateurId: string, articleId: string, quantite: number) {
    const panier = await this.panierActif(utilisateurId);
    const { count } = await this.prisma.articlePanier.updateMany({
      where: { id: articleId, panierId: panier.id },
      data: { quantite },
    });
    if (!count) throw new NotFoundException('Article de panier introuvable.');
    await this.toucher(panier.id);
    return this.obtenir(utilisateurId);
  }

  async supprimer(utilisateurId: string, articleId: string) {
    const panier = await this.panierActif(utilisateurId);
    const resultat = await this.prisma.articlePanier.deleteMany({
      where: { id: articleId, panierId: panier.id },
    });
    if (!resultat.count)
      throw new NotFoundException('Article de panier introuvable.');
    await this.toucher(panier.id);
    return this.obtenir(utilisateurId);
  }

  async panierActif(utilisateurId: string) {
    const existant = await this.prisma.panier.findFirst({
      where: { utilisateurId, statut: 'ACTIF' },
      select: { id: true },
    });
    if (existant) return existant;
    return this.prisma.panier.create({
      data: { utilisateurId, statut: 'ACTIF' },
      select: { id: true },
    });
  }

  /** Activité du panier : repousse son passage en « abandonné ». */
  private toucher(panierId: string) {
    return this.prisma.panier.update({
      where: { id: panierId },
      data: { dateModification: new Date() },
    });
  }

  /**
   * Prix et disponibilité recalculés à chaque affichage : le prix enregistré
   * à l'ajout peut avoir changé (prixModifie), le produit peut ne plus être
   * en vente ou le stock être insuffisant (disponible = false).
   */
  private formater(panier: PanierBrut | null) {
    if (!panier) {
      return { id: null, articles: [], sousTotal: 0, devise: 'XAF', commandable: false };
    }
    const articles = panier.articles.map((article) => {
      const { produit, ...variante } = article.varianteProduit;
      const { boutique } = produit;
      const prixActuel = variante.prix ?? produit.prixBase;
      const enVente =
        produit.statut === 'PUBLIE' &&
        boutique.statut === 'ACTIVE' &&
        boutique.vendeur.statutVendeur === 'ACTIF' &&
        boutique.vendeur.utilisateur.statutCompte === 'ACTIF';
      const stockSuffisant = variante.stockDisponible >= article.quantite;
      return {
        id: article.id,
        varianteProduitId: article.varianteProduitId,
        quantite: article.quantite,
        prixUnitaire: Number(prixActuel),
        prixModifie: !prixActuel.equals(article.prixUnitaire),
        total: Number(prixActuel.mul(article.quantite)),
        disponible: enVente && stockSuffisant,
        stockDisponible: variante.stockDisponible,
        variante: {
          id: variante.id,
          sku: variante.sku,
          nom: variante.nom,
          attributs: variante.attributs,
        },
        produit: {
          id: produit.id,
          nom: produit.nom,
          boutiqueId: produit.boutiqueId,
          boutiqueNom: boutique.nom,
        },
      };
    });
    const sousTotal = articles
      .filter((a) => a.disponible)
      .reduce((total, a) => total + a.total, 0);
    return {
      id: panier.id,
      statut: panier.statut,
      dateModification: panier.dateModification,
      articles,
      sousTotal,
      devise: 'XAF',
      commandable: articles.length > 0 && articles.every((a) => a.disponible),
    };
  }
}
