import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { CommenterDto } from '../dto/commenter.dto.js';
import { verifierPublicationVisible } from '../utils/publications.js';

/** Regex pour extraire les mentions @username du contenu. */
const MENTION_REGEX = /@([a-zA-Z0-9_]{2,30})/g;

@Injectable()
export class CommentaireService {
  constructor(private readonly prisma: PrismaService) {}

  async commenter(
    utilisateurId: string,
    publicationId: string,
    dto: CommenterDto,
  ) {
    const publication = await verifierPublicationVisible(
      this.prisma,
      publicationId,
    );
    // Vérification du parent si c'est une réponse
    if (dto.parentId) {
      const parent = await this.prisma.commentaire.findUnique({
        where: { id: dto.parentId },
        select: { id: true, publicationId: true, parentId: true, statut: true },
      });

      if (
        !parent ||
        parent.publicationId !== publicationId ||
        parent.statut !== 'VISIBLE'
      ) {
        throw new NotFoundException('Commentaire parent introuvable.');
      }

      // Sécurité supplémentaire côté application (le trigger gère côté base)
      if (parent.parentId !== null) {
        throw new BadRequestException('Impossible de répondre à une réponse.');
      }
    }

    // Badge créateur : l'utilisateur est-il le propriétaire de la boutique ?
    const estCreateur = utilisateurId === publication.boutiqueId;

    // Extraction des mentions
    const mentions = [...dto.contenu.matchAll(MENTION_REGEX)].map((m) => m[1]);

    const commentaire = await this.prisma.commentaire.create({
      data: {
        utilisateurId,
        publicationId,
        contenu: dto.contenu,
        parentId: dto.parentId ?? null,
        estCreateur,
      },
      select: {
        id: true,
        contenu: true,
        parentId: true,
        estCreateur: true,
        dateCreation: true,
        utilisateur: {
          select: { id: true, prenom: true, nom: true },
        },
      },
    });

    return { ...commentaire, mentions };
  }

  /**
   * Un utilisateur peut supprimer ses propres commentaires.
   * Le propriétaire de la boutique peut supprimer n'importe quel commentaire
   * sur ses publications.
   */
  async supprimer(utilisateurId: string, commentaireId: string): Promise<void> {
    const commentaire = await this.prisma.commentaire.findUnique({
      where: { id: commentaireId },
      select: {
        id: true,
        utilisateurId: true,
        publication: { select: { boutiqueId: true } },
      },
    });

    if (!commentaire) throw new NotFoundException('Commentaire introuvable.');

    const estAuteur = commentaire.utilisateurId === utilisateurId;
    const estProprietaireBoutique =
      commentaire.publication.boutiqueId === utilisateurId;

    if (!estAuteur && !estProprietaireBoutique) {
      throw new ForbiddenException('Action non autorisée.');
    }

    await this.prisma.commentaire.update({
      where: { id: commentaireId },
      data: { statut: 'SUPPRIME' },
    });
  }
}
