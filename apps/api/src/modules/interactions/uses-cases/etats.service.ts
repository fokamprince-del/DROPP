import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

/**
 * Retourne en une seule requête tous les états d'interaction
 * de l'utilisateur connecté. Appelé au démarrage de l'app
 * pour initialiser le cache local.
 */
@Injectable()
export class EtatsUtilisateurService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(utilisateurId: string) {
    const [
      likesPublications,
      likesCommentaires,
      favorisPublications,
      favorisProduits,
      abonnements,
    ] = await this.prisma.$transaction([
      this.prisma.aime.findMany({
        where: { utilisateurId },
        select: { publicationId: true },
      }),
      this.prisma.aimeCommentaire.findMany({
        where: { utilisateurId },
        select: { commentaireId: true },
      }),
      this.prisma.favoriPublication.findMany({
        where: { utilisateurId },
        select: { publicationId: true },
      }),
      this.prisma.favoriProduit.findMany({
        where: { utilisateurId },
        select: { produitId: true },
      }),
      this.prisma.abonnement.findMany({
        where: { utilisateurId, statut: 'ACTIF' },
        select: { vendeurId: true },
      }),
    ]);

    return {
      likesPublications: likesPublications.map((l) => l.publicationId),
      likesCommentaires: likesCommentaires.map((l) => l.commentaireId),
      favorisPublications: favorisPublications.map((f) => f.publicationId),
      favorisProduits: favorisProduits.map((f) => f.produitId),
      abonnements: abonnements.map((a) => a.vendeurId),
    };
  }
}
