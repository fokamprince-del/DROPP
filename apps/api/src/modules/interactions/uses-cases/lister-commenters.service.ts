import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { verifierPublicationVisible } from '../utils/publications.js';

const LIMITE_PAR_PAGE = 20;
const LIMITE_REPONSES = 3; // Réponses affichées par défaut sous chaque commentaire

@Injectable()
export class ListerCommentairesService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(publicationId: string, page: number, utilisateurId?: string) {
    // Même règle que la publication : pas de commentaires d'une publication
    // réservée aux abonnés pour un non-abonné (ou un visiteur anonyme).
    await verifierPublicationVisible(this.prisma, publicationId, utilisateurId);

    const commentaires = await this.prisma.commentaire.findMany({
      where: {
        publicationId,
        parentId: null, // Uniquement les commentaires racines
        statut: 'VISIBLE',
      },
      select: {
        id: true,
        contenu: true,
        estCreateur: true,
        dateCreation: true,
        utilisateur: {
          select: { id: true, prenom: true, nom: true },
        },
        // Compteur de likes
        _count: {
          select: { likesCommentaire: true, reponses: true },
        },
        // Premières réponses (aperçu)
        reponses: {
          where: { statut: 'VISIBLE' },
          take: LIMITE_REPONSES,
          orderBy: { dateCreation: 'asc' },
          select: {
            id: true,
            contenu: true,
            estCreateur: true,
            dateCreation: true,
            utilisateur: {
              select: { id: true, prenom: true, nom: true },
            },
            _count: { select: { likesCommentaire: true } },
          },
        },
      },
      orderBy: { dateCreation: 'desc' },
      skip: (page - 1) * LIMITE_PAR_PAGE,
      take: LIMITE_PAR_PAGE,
    });

    const total = await this.prisma.commentaire.count({
      where: { publicationId, parentId: null, statut: 'VISIBLE' },
    });

    // Si l'utilisateur est connecté, on indique s'il a liké chaque commentaire
    let likesUtilisateur: Set<string> = new Set();
    if (utilisateurId) {
      const ids = commentaires.map((c) => c.id);
      const likes = await this.prisma.aimeCommentaire.findMany({
        where: { utilisateurId, commentaireId: { in: ids } },
        select: { commentaireId: true },
      });
      likesUtilisateur = new Set(likes.map((l) => l.commentaireId));
    }

    return {
      donnees: commentaires.map((c) => ({
        ...c,
        likes: c._count.likesCommentaire,
        totalReponses: c._count.reponses,
        likeParMoi: likesUtilisateur.has(c.id),
        reponses: c.reponses.map((r) => ({
          ...r,
          likes: r._count.likesCommentaire,
        })),
      })),
      pagination: {
        total,
        page,
        pages: Math.ceil(total / LIMITE_PAR_PAGE),
      },
    };
  }

  /** Charge toutes les réponses d'un commentaire racine (bouton "voir plus"). */
  async listerReponses(
    commentaireId: string,
    page: number,
    utilisateurId?: string,
  ) {
    const parent = await this.prisma.commentaire.findUnique({
      where: { id: commentaireId },
      select: { publicationId: true },
    });
    if (!parent) throw new NotFoundException('Commentaire introuvable.');
    await verifierPublicationVisible(this.prisma, parent.publicationId, utilisateurId);

    const reponses = await this.prisma.commentaire.findMany({
      where: { parentId: commentaireId, statut: 'VISIBLE' },
      select: {
        id: true,
        contenu: true,
        estCreateur: true,
        dateCreation: true,
        utilisateur: {
          select: { id: true, prenom: true, nom: true },
        },
        _count: { select: { likesCommentaire: true } },
      },
      orderBy: { dateCreation: 'asc' },
      skip: (page - 1) * LIMITE_PAR_PAGE,
      take: LIMITE_PAR_PAGE,
    });

    const total = await this.prisma.commentaire.count({
      where: { parentId: commentaireId, statut: 'VISIBLE' },
    });

    let likesUtilisateur: Set<string> = new Set();
    if (utilisateurId) {
      const ids = reponses.map((r) => r.id);
      const likes = await this.prisma.aimeCommentaire.findMany({
        where: { utilisateurId, commentaireId: { in: ids } },
        select: { commentaireId: true },
      });
      likesUtilisateur = new Set(likes.map((l) => l.commentaireId));
    }

    return {
      donnees: reponses.map((r) => ({
        ...r,
        likes: r._count.likesCommentaire,
        likeParMoi: likesUtilisateur.has(r.id),
      })),
      pagination: {
        total,
        page,
        pages: Math.ceil(total / LIMITE_PAR_PAGE),
      },
    };
  }
}
