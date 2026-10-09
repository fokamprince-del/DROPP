import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';

@Injectable()
export class StatsService {
  constructor(private readonly prisma: PrismaService) {}

  async executer() {
    const maintenant = new Date();
    const debutMois = new Date(
      maintenant.getFullYear(),
      maintenant.getMonth(),
      1,
    );

    const [
      totalUtilisateurs,
      nouveauxUtilisateursCeMois,
      utilisateursActifs,
      totalVendeurs,
      vendeursActifs,
      vendeursEnAttenteKyc,
      totalProduits,
      produitsPublies,
      totalCommandes,
      commandesCeMois,
      totalSignalementsOuverts,
      dossiersKycEnAttenteRevue,
    ] = await this.prisma.$transaction([
      this.prisma.utilisateur.count(),
      this.prisma.utilisateur.count({
        where: { dateInscription: { gte: debutMois } },
      }),
      this.prisma.utilisateur.count({ where: { statutCompte: 'ACTIF' } }),
      this.prisma.vendeur.count(),
      this.prisma.vendeur.count({ where: { statutVendeur: 'ACTIF' } }),
      this.prisma.vendeur.count({
        where: { statutVendeur: 'EN_ATTENTE_VALIDATION' },
      }),
      this.prisma.produit.count(),
      this.prisma.produit.count({ where: { statut: 'PUBLIE' } }),
      this.prisma.commande.count(),
      this.prisma.commande.count({
        where: { dateCreation: { gte: debutMois } },
      }),
      this.prisma.signalement.count({
        where: { statut: { in: ['OUVERT', 'EN_COURS'] } },
      }),
      this.prisma.dossierKyc.count({
        where: { statut: 'EN_ATTENTE_REVUE_ADMIN' },
      }),
    ]);

    return {
      utilisateurs: {
        total: totalUtilisateurs,
        nouveauxCeMois: nouveauxUtilisateursCeMois,
        actifs: utilisateursActifs,
      },
      vendeurs: {
        total: totalVendeurs,
        actifs: vendeursActifs,
        enAttenteKyc: vendeursEnAttenteKyc,
      },
      produits: {
        total: totalProduits,
        publies: produitsPublies,
      },
      commandes: {
        total: totalCommandes,
        ceMois: commandesCeMois,
      },
      moderation: {
        signalementsOuverts: totalSignalementsOuverts,
        dossiersKycEnAttente: dossiersKycEnAttenteRevue,
      },
    };
  }
}