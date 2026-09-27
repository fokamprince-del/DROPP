import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';

const commandeSelect = {
  id: true,
  statut: true,
  montantTotal: true,
  devise: true,
  dateCreation: true,
  sousCommandes: {
    select: {
      id: true,
      vendeurId: true,
      statut: true,
      sousTotal: true,
      montantTotal: true,
      lignes: {
        select: {
          id: true,
          nomProduitSnapshot: true,
          quantite: true,
          prixUnitaire: true,
          varianteSnapshot: true,
        },
      },
    },
  },
} as const;

@Injectable()
export class CommandeService {
  constructor(private readonly prisma: PrismaService) {}

  async passer(utilisateurId: string) {
    return this.prisma.$transaction(async (tx) => {
      const panier = await tx.panier.findFirst({
        where: { utilisateurId, statut: 'ACTIF' },
        select: {
          id: true,
          articles: {
            select: {
              id: true,
              quantite: true,
              prixUnitaire: true,
              varianteProduit: {
                select: {
                  id: true,
                  nom: true,
                  sku: true,
                  attributs: true,
                  prix: true,
                  stockDisponible: true,
                  produit: {
                    select: {
                      id: true,
                      nom: true,
                      prixBase: true,
                      boutiqueId: true,
                      statut: true,
                      boutique: {
                        select: { vendeur: { select: { id: true } } },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      });
      if (!panier || panier.articles.length === 0)
        throw new BadRequestException('Le panier est vide.');

      const prixCourants = new Map(
        panier.articles.map((article) => [
          article.id,
          Number(
            article.varianteProduit.prix ??
              article.varianteProduit.produit.prixBase,
          ),
        ]),
      );
      const total = panier.articles.reduce(
        (somme, article) =>
          somme + (prixCourants.get(article.id) ?? 0) * article.quantite,
        0,
      );
      const passage = await tx.passageCommande.create({
        data: {
          utilisateurId,
          panierId: panier.id,
          montantTotal: total,
          devise: 'XAF',
        },
      });
      const groupes = new Map<string, typeof panier.articles>();
      for (const article of panier.articles) {
        if (article.varianteProduit.produit.statut !== 'PUBLIE')
          throw new BadRequestException(
            'Un produit du panier n’est plus disponible.',
          );
        const vendeurId = article.varianteProduit.produit.boutique.vendeur.id;
        const groupe = groupes.get(vendeurId) ?? [];
        groupe.push(article);
        groupes.set(vendeurId, groupe);
      }

      const commande = await tx.commande.create({
        data: {
          passageCommandeId: passage.id,
          utilisateurId,
          montantTotal: total,
          devise: 'XAF',
        },
      });
      for (const [vendeurId, articles] of groupes) {
        const sousTotal = articles.reduce(
          (somme, article) =>
            somme + (prixCourants.get(article.id) ?? 0) * article.quantite,
          0,
        );
        const sousCommande = await tx.sousCommande.create({
          data: {
            commandeId: commande.id,
            vendeurId,
            sousTotal,
            montantTotal: sousTotal,
            devise: 'XAF',
          },
        });
        for (const article of articles) {
          const reserve = await tx.varianteProduit.updateMany({
            where: {
              id: article.varianteProduit.id,
              stockDisponible: { gte: article.quantite },
            },
            data: { stockDisponible: { decrement: article.quantite } },
          });
          if (reserve.count !== 1)
            throw new BadRequestException(
              `Stock insuffisant pour ${article.varianteProduit.nom}.`,
            );
          await tx.reservationStock.create({
            data: {
              varianteProduitId: article.varianteProduit.id,
              quantite: article.quantite,
              expireA: new Date(Date.now() + 30 * 60_000),
              passageCommandeId: passage.id,
            },
          });
          await tx.ligneSousCommande.create({
            data: {
              articleCommandeId: sousCommande.id,
              produitId: article.varianteProduit.produit.id,
              varianteProduitId: article.varianteProduit.id,
              produitSnapshot: {
                id: article.varianteProduit.produit.id,
                nom: article.varianteProduit.produit.nom,
                prixBase: Number(article.varianteProduit.produit.prixBase),
              },
              varianteSnapshot: {
                id: article.varianteProduit.id,
                nom: article.varianteProduit.nom,
                sku: article.varianteProduit.sku,
                attributs: article.varianteProduit.attributs,
              },
              nomProduitSnapshot: article.varianteProduit.produit.nom,
              quantite: article.quantite,
              prixUnitaire: prixCourants.get(article.id) ?? 0,
            },
          });
        }
      }
      await tx.articlePanier.deleteMany({ where: { panierId: panier.id } });
      await tx.panier.update({
        where: { id: panier.id },
        data: { statut: 'CONVERTI' },
      });
      return {
        ...commande,
        montantTotal: total,
        paiement: { statut: 'NON_CONFIGURE' },
        livraison: { statut: 'A_DEFINIR' },
      };
    });
  }

  async lister(utilisateurId: string) {
    const commandes = await this.prisma.commande.findMany({
      where: { utilisateurId },
      orderBy: { dateCreation: 'desc' },
      select: commandeSelect,
    });
    return commandes.map((commande) => ({
      ...commande,
      montantTotal: Number(commande.montantTotal),
    }));
  }

  async obtenir(utilisateurId: string, id: string) {
    const commande = await this.prisma.commande.findFirst({
      where: { id, utilisateurId },
      select: commandeSelect,
    });
    if (!commande) throw new NotFoundException('Commande introuvable.');
    return {
      ...commande,
      montantTotal: Number(commande.montantTotal),
      paiement: { statut: 'NON_CONFIGURE' },
      livraison: { statut: 'A_DEFINIR' },
    };
  }
}
