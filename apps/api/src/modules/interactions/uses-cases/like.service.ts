import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { NotificateurService } from '../../notifications/notificateur.service.js';
import { verifierPublicationVisible } from '../utils/publications.js';

@Injectable()
export class LikeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificateur: NotificateurService,
  ) {}

  async likerPublication(utilisateurId: string, publicationId: string) {
    const publication = await verifierPublicationVisible(
      this.prisma,
      publicationId,
    );

    try {
      await this.prisma.aime.create({
        data: { utilisateurId, publicationId },
      });
    } catch (e: unknown) {
      if (this.estViolationUnicite(e)) {
        throw new ConflictException('Publication déjà likée.');
      }
      throw e;
    }

    const total = await this.prisma.aime.count({ where: { publicationId } });

    if (publication.boutiqueId !== utilisateurId) {
      void this.notificateur.nomAffiche(utilisateurId).then((nom) =>
        this.notificateur.notifier({
          utilisateurId: publication.boutiqueId,
          type: 'SOCIAL',
          titre: 'Nouveau j’aime',
          contenu: `${nom} a aimé votre publication.`,
          donnees: { publicationId },
          // Like / unlike / like en boucle = une seule notification.
          cleDedoublonnage: `like:${publicationId}:${utilisateurId}`,
        }),
      );
    }

    return { publicationId, likes: total };
  }

  async unlikerPublication(utilisateurId: string, publicationId: string) {
    const like = await this.prisma.aime.findUnique({
      where: {
        utilisateurId_publicationId: { utilisateurId, publicationId },
      },
      select: { id: true },
    });

    if (!like) throw new NotFoundException('Like introuvable.');

    await this.prisma.aime.delete({
      where: {
        utilisateurId_publicationId: { utilisateurId, publicationId },
      },
    });

    const total = await this.prisma.aime.count({ where: { publicationId } });
    return { publicationId, likes: total };
  }

  async likerCommentaire(utilisateurId: string, commentaireId: string) {
    const commentaire = await this.prisma.commentaire.findUnique({
      where: { id: commentaireId },
      select: { id: true, statut: true },
    });

    if (!commentaire || commentaire.statut !== 'VISIBLE') {
      throw new NotFoundException('Commentaire introuvable.');
    }

    try {
      await this.prisma.aimeCommentaire.create({
        data: { utilisateurId, commentaireId },
      });
    } catch (e: unknown) {
      if (this.estViolationUnicite(e)) {
        throw new ConflictException('Commentaire déjà liké.');
      }
      throw e;
    }

    const total = await this.prisma.aimeCommentaire.count({
      where: { commentaireId },
    });
    return { commentaireId, likes: total };
  }

  async unlikerCommentaire(utilisateurId: string, commentaireId: string) {
    const like = await this.prisma.aimeCommentaire.findUnique({
      where: {
        utilisateurId_commentaireId: { utilisateurId, commentaireId },
      },
      select: { id: true },
    });

    if (!like) throw new NotFoundException('Like introuvable.');

    await this.prisma.aimeCommentaire.delete({
      where: {
        utilisateurId_commentaireId: { utilisateurId, commentaireId },
      },
    });

    const total = await this.prisma.aimeCommentaire.count({
      where: { commentaireId },
    });
    return { commentaireId, likes: total };
  }

  private estViolationUnicite(e: unknown): boolean {
    return (
      typeof e === 'object' &&
      e !== null &&
      'code' in e &&
      (e as { code: string }).code === 'P2002'
    );
  }
}
