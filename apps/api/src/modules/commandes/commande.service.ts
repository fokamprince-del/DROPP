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

import { Prisma, type StatutCommande } from '@dropp/database';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { NotificateurService } from '../notifications/notificateur.service.js';
import { BOUTIQUE_VISIBLE } from '../shops/boutique-visible.js';

const ligneSelect = {
  id: true,
  produitId: true,
  nomProduitSnapshot: true,
  quantite: true,
  prixUnitaire: true,
  varianteSnapshot: true,
} as const;

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
      vendeur: { select: { boutique: { select: { nom: true } } } },
      lignes: { select: ligneSelect },
    },
  },
} as const;

/** Marge avant que le balayage ne rattrape une expiration non traitée. */
const MARGE_BALAYAGE_MS = 5 * 60_000;
const LOT_BALAYAGE = 100;

/** Paiement et livraison : à brancher (prestataires en cours de sélection). */
const ETAT_EN_ATTENTE = {
  paiement: { statut: 'NON_CONFIGURE' },
  livraison: { statut: 'A_DEFINIR' },
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
    // Si l'ajout échoue, le balayage périodique prend le relais.
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

    return this.obtenir(utilisateurId, commande.id);
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

    const annulee = await this.libererCommande(commande.passageCommandeId, 'ANNULE');
    if (!annulee) {
      throw new ConflictException('Cette commande a déjà été traitée.');
    }
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
   * Filet de sécurité (planifié) : expire les commandes non payées dont le
   * délai est dépassé mais dont le job différé n'a pas tourné (Redis vidé,
   * ajout du job en échec…). Le stock réservé est ainsi toujours rendu.
   */
  async expirerEnRetard(): Promise<number> {
    const limite = new Date(Date.now() - this.delaiPaiementMs - MARGE_BALAYAGE_MS);
    const enRetard = await this.prisma.commande.findMany({
      where: { statut: 'EN_ATTENTE_PAIEMENT', dateCreation: { lt: limite } },
      select: { passageCommandeId: true },
      take: LOT_BALAYAGE,
    });
    for (const { passageCommandeId } of enRetard) {
      await this.expirer(passageCommandeId).catch((e: unknown) =>
        this.logger.error(`Expiration ${passageCommandeId} : ${String(e)}`),
      );
    }
    return enRetard.length;
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

      // Garde atomique : un seul appelant (job, balayage ou client) passe ici.
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
              varianteProduit: {
                select: {
                  id: true,
                  nom: true,
                  sku: true,
                  attributs: true,
                  prix: true,
                  produit: {
                    select: {
                      id: true,
                      nom: true,
                      prixBase: true,
                      boutiqueId: true,
                      statut: true,
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

      // Produits encore en vente, dans une boutique visible.
      const produitIds = [
        ...new Set(panier.articles.map((a) => a.varianteProduit.produit.id)),
      ];
      const enVente = await tx.produit.count({
        where: {
          id: { in: produitIds },
          statut: 'PUBLIE',
          boutique: BOUTIQUE_VISIBLE,
        },
      });
      if (enVente !== produitIds.length) {
        throw new BadRequestException(
          'Un produit du panier n’est plus disponible. Retirez-le pour continuer.',
        );
      }

      // Prix courants (et non ceux enregistrés à l'ajout au panier), en Decimal.
      const prixCourant = new Map(
        panier.articles.map((a) => [
          a.id,
          a.varianteProduit.prix ?? a.varianteProduit.produit.prixBase,
        ]),
      );
      const montant = (articles: typeof panier.articles) =>
        articles.reduce(
          (somme, a) => somme.add(prixCourant.get(a.id)!.mul(a.quantite)),
          new Prisma.Decimal(0),
        );

      const groupes = new Map<string, typeof panier.articles>();
      for (const article of panier.articles) {
        const vendeurId = article.varianteProduit.produit.boutiqueId;
        if (vendeurId === utilisateurId)
          throw new BadRequestException(
            'Vous ne pouvez pas commander dans votre propre boutique.',
          );
        groupes.set(vendeurId, [...(groupes.get(vendeurId) ?? []), article]);
      }

      const total = montant(panier.articles);
      if (total.lte(0)) {
        throw new BadRequestException('Montant de commande invalide.');
      }

      const passage = await tx.passageCommande.create({
        data: {
          utilisateurId,
          panierId: panier.id,
          montantTotal: total,
          devise: 'XAF',
        },
      });
      const commande = await tx.commande.create({
        data: {
          passageCommandeId: passage.id,
          utilisateurId,
          montantTotal: total,
          devise: 'XAF',
        },
      });

      for (const [vendeurId, articles] of groupes) {
        const sousTotal = montant(articles);
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
          const { varianteProduit: variante } = article;
          const reserve = await tx.varianteProduit.updateMany({
            where: {
              id: variante.id,
              stockDisponible: { gte: article.quantite },
            },
            data: { stockDisponible: { decrement: article.quantite } },
          });
          if (reserve.count !== 1)
            throw new BadRequestException(
              `Stock insuffisant pour ${variante.produit.nom} (${variante.nom}).`,
            );
          await tx.reservationStock.create({
            data: {
              varianteProduitId: variante.id,
              quantite: article.quantite,
              expireA: new Date(Date.now() + this.delaiPaiementMs),
              passageCommandeId: passage.id,
            },
          });
          await tx.ligneSousCommande.create({
            data: {
              articleCommandeId: sousCommande.id,
              produitId: variante.produit.id,
              varianteProduitId: variante.id,
              produitSnapshot: {
                id: variante.produit.id,
                nom: variante.produit.nom,
                prixBase: variante.produit.prixBase.toString(),
              },
              varianteSnapshot: {
                id: variante.id,
                nom: variante.nom,
                sku: variante.sku,
                attributs: variante.attributs as Prisma.InputJsonValue,
              },
              nomProduitSnapshot: variante.produit.nom,
              quantite: article.quantite,
              prixUnitaire: prixCourant.get(article.id)!,
            },
          });
        }
      }
      await tx.articlePanier.deleteMany({ where: { panierId: panier.id } });
      await tx.panier.update({
        where: { id: panier.id },
        data: { statut: 'CONVERTI' },
      });
      return { id: commande.id, passageCommandeId: passage.id };
    });
  }

  async lister(utilisateurId: string, page: number, limite: number) {
    const where = { utilisateurId };
    const [commandes, total] = await this.prisma.$transaction([
      this.prisma.commande.findMany({
        where,
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
        select: commandeSelect,
      }),
      this.prisma.commande.count({ where }),
    ]);
    return {
      donnees: commandes.map((c) => this.presenter(c)),
      pagination: { total, page, limite, pages: Math.ceil(total / limite) },
    };
  }

  async obtenir(utilisateurId: string, id: string) {
    const commande = await this.prisma.commande.findFirst({
      where: { id, utilisateurId },
      select: commandeSelect,
    });
    if (!commande) throw new NotFoundException('Commande introuvable.');
    return { ...this.presenter(commande), ...ETAT_EN_ATTENTE };
  }

  // ── Côté vendeur (lecture seule tant que paiement et livraison manquent) ──

  async listerVentes(
    vendeurId: string,
    page: number,
    limite: number,
    statut?: StatutCommande,
  ) {
    const where = { vendeurId, ...(statut && { statut }) };
    const [ventes, total] = await this.prisma.$transaction([
      this.prisma.sousCommande.findMany({
        where,
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
        select: this.venteSelect,
      }),
      this.prisma.sousCommande.count({ where }),
    ]);
    return {
      donnees: ventes.map((v) => this.presenterVente(v)),
      pagination: { total, page, limite, pages: Math.ceil(total / limite) },
    };
  }

  async obtenirVente(vendeurId: string, sousCommandeId: string) {
    const vente = await this.prisma.sousCommande.findFirst({
      where: { id: sousCommandeId, vendeurId },
      select: this.venteSelect,
    });
    if (!vente) throw new NotFoundException('Commande introuvable.');
    return { ...this.presenterVente(vente), ...ETAT_EN_ATTENTE };
  }

  private readonly venteSelect = {
    id: true,
    commandeId: true,
    statut: true,
    sousTotal: true,
    montantTotal: true,
    devise: true,
    dateCreation: true,
    commande: {
      select: {
        utilisateur: { select: { id: true, prenom: true, nom: true, pseudo: true } },
      },
    },
    lignes: { select: ligneSelect },
  } satisfies Prisma.SousCommandeSelect;

  private presenterVente(
    v: Prisma.SousCommandeGetPayload<{ select: CommandeService['venteSelect'] }>,
  ) {
    const { commande, ...vente } = v;
    return {
      ...vente,
      sousTotal: Number(vente.sousTotal),
      montantTotal: Number(vente.montantTotal),
      client: commande.utilisateur,
      lignes: vente.lignes.map((l) => ({ ...l, prixUnitaire: Number(l.prixUnitaire) })),
    };
  }

  private presenter(
    c: Prisma.CommandeGetPayload<{ select: typeof commandeSelect }>,
  ) {
    return {
      ...c,
      montantTotal: Number(c.montantTotal),
      sousCommandes: c.sousCommandes.map(({ vendeur, ...sc }) => ({
        ...sc,
        boutiqueNom: vendeur.boutique?.nom ?? null,
        sousTotal: Number(sc.sousTotal),
        montantTotal: Number(sc.montantTotal),
        lignes: sc.lignes.map((l) => ({ ...l, prixUnitaire: Number(l.prixUnitaire) })),
      })),
    };
  }
}
