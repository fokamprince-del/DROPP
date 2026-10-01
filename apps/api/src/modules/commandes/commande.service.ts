import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';
import type { Queue } from 'bullmq';

import {
  JOB_COMMANDE,
  QUEUE_COMMANDE,
  type JobExpirationPassage,
} from '@dropp/contrats';

import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { NotificateurService } from '../notifications/notificateur.service.js';

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
  private readonly logger = new Logger(CommandeService.name);
  private readonly delaiPaiementMs: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificateur: NotificateurService,
    @InjectQueue(QUEUE_COMMANDE) private readonly queue: Queue,
    config: ConfigService,
  ) {
    this.delaiPaiementMs =
      config.getOrThrow<number>('commande.delaiPaiementMinutes') * 60_000;
  }

  async passer(utilisateurId: string) {
    const commande = await this.creerCommande(utilisateurId);

    // Sans paiement dans le délai : annulation et stock rendu (voir expirer()).
    // jobId déterministe : le module paiement pourra retirer le job une fois payé.
    await this.queue
      .add(
        JOB_COMMANDE.EXPIRATION_PASSAGE,
        { passageCommandeId: commande.passageCommandeId } satisfies JobExpirationPassage,
        {
          delay: this.delaiPaiementMs,
          jobId: `expiration-${commande.passageCommandeId}`,
        },
      )
      .catch((erreur: unknown) =>
        this.logger.error(
          `Job d'expiration non planifié (${commande.passageCommandeId}) : ${String(erreur)}`,
        ),
      );

    void this.notificateur.notifier({
      utilisateurId,
      type: 'COMMANDE',
      titre: 'Commande enregistrée',
      contenu: `Finalisez le paiement dans les ${this.delaiPaiementMs / 60_000} minutes pour confirmer votre commande.`,
      donnees: { commandeId: commande.id },
    });

    return commande;
  }

  /** Annulation par le client, possible tant que la commande n'est pas payée. */
  async annuler(utilisateurId: string, commandeId: string) {
    const commande = await this.prisma.commande.findFirst({
      where: { id: commandeId, utilisateurId },
      select: { statut: true, passageCommandeId: true },
    });
    if (!commande) throw new NotFoundException('Commande introuvable.');
    if (commande.statut !== 'EN_ATTENTE_PAIEMENT') {
      throw new ConflictException(
        'Cette commande ne peut plus être annulée depuis l’application.',
      );
    }

    await this.libererCommande(commande.passageCommandeId, 'ANNULE');
    await this.queue
      .remove(`expiration-${commande.passageCommandeId}`)
      .catch(() => undefined);
    return this.obtenir(utilisateurId, commandeId);
  }

  /** Appelé par le job d'expiration : ne fait rien si la commande a été payée entre-temps. */
  async expirer(passageCommandeId: string): Promise<void> {
    const commande = await this.libererCommande(passageCommandeId, 'EXPIRE');
    if (!commande) return;

    await this.notificateur.notifier({
      utilisateurId: commande.utilisateurId,
      type: 'COMMANDE',
      titre: 'Commande annulée',
      contenu:
        'Le paiement n’a pas été reçu à temps : votre commande a été annulée.',
      donnees: { commandeId: commande.id },
    });
  }

  /**
   * Annule une commande non payée et rend le stock réservé, de façon atomique.
   * Retourne null si la commande n'est plus EN_ATTENTE_PAIEMENT (payée, déjà annulée…).
   */
  private async libererCommande(
    passageCommandeId: string,
    statutPassage: 'EXPIRE' | 'ANNULE',
  ) {
    return this.prisma.$transaction(async (tx) => {
      const commande = await tx.commande.findUnique({
        where: { passageCommandeId },
        select: { id: true, utilisateurId: true },
      });
      if (!commande) return null;

      // Garde atomique : un seul appelant (job ou client) passe ici.
      const { count } = await tx.commande.updateMany({
        where: { id: commande.id, statut: 'EN_ATTENTE_PAIEMENT' },
        data: { statut: 'ANNULEE' },
      });
      if (count === 0) return null;

      await tx.sousCommande.updateMany({
        where: { commandeId: commande.id },
        data: { statut: 'ANNULEE' },
      });

      const reservations = await tx.reservationStock.findMany({
        where: { passageCommandeId },
        select: { varianteProduitId: true, quantite: true },
      });
      for (const r of reservations) {
        await tx.varianteProduit.update({
          where: { id: r.varianteProduitId },
          data: { stockDisponible: { increment: r.quantite } },
        });
      }
      await tx.reservationStock.deleteMany({ where: { passageCommandeId } });
      await tx.passageCommande.update({
        where: { id: passageCommandeId },
        data: { statut: statutPassage },
      });

      return commande;
    });
  }

  private async creerCommande(utilisateurId: string) {
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
        if (vendeurId === utilisateurId)
          throw new BadRequestException(
            'Vous ne pouvez pas commander dans votre propre boutique.',
          );
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
              expireA: new Date(Date.now() + this.delaiPaiementMs),
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
