import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { NotificateurService } from '../../notifications/notificateur.service.js';
import type { CommenterDto } from '../dto/commenter.dto.js';
import { extraireMentions } from '../../users/pseudo.js';
import { verifierPublicationVisible } from '../utils/publications.js';

@Injectable()
export class CommentaireService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificateur: NotificateurService,
  ) {}

  async commenter(
    utilisateurId: string,
    publicationId: string,
    dto: CommenterDto,
  ) {
    const publication = await verifierPublicationVisible(
      this.prisma,
      publicationId,
      utilisateurId,
    );
    const bloque = await this.prisma.blocage.count({
      where: {
        OR: [
          { bloqueurId: publication.boutiqueId, bloqueId: utilisateurId },
          { bloqueurId: utilisateurId, bloqueId: publication.boutiqueId },
        ],
      },
    });
    if (bloque > 0) {
      throw new ForbiddenException('Vous ne pouvez pas commenter cette publication.');
    }

    // Vérification du parent si c'est une réponse
    let auteurParentId: string | null = null;
    if (dto.parentId) {
      const parent = await this.prisma.commentaire.findUnique({
        where: { id: dto.parentId },
        select: {
          id: true,
          publicationId: true,
          parentId: true,
          statut: true,
          utilisateurId: true,
        },
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
      auteurParentId = parent.utilisateurId;
    }

    // Badge créateur : l'utilisateur est-il le propriétaire de la boutique ?
    const estCreateur = utilisateurId === publication.boutiqueId;

    // Mentions : seuls les @pseudos existants (comptes actifs) sont retenus.
    const pseudos = extraireMentions(dto.contenu);
    const mentions = pseudos.length
      ? await this.prisma.utilisateur.findMany({
          where: { pseudo: { in: pseudos }, statutCompte: 'ACTIF' },
          select: { id: true, pseudo: true },
        })
      : [];

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
          select: { id: true, prenom: true, nom: true, pseudo: true },
        },
      },
    });

    void this.notifierCommentaire(
      utilisateurId,
      publicationId,
      publication.boutiqueId,
      auteurParentId,
      commentaire.id,
      dto.contenu,
      mentions.map((m) => m.id),
    );

    return { ...commentaire, mentions };
  }

  /** Vendeur : nouveau commentaire. Auteur du parent : réponse. Jamais soi-même. */
  private async notifierCommentaire(
    auteurId: string,
    publicationId: string,
    vendeurId: string,
    auteurParentId: string | null,
    commentaireId: string,
    contenu: string,
    mentionnes: string[],
  ) {
    const nom = await this.notificateur.nomAffiche(auteurId);
    const extrait = contenu.length > 80 ? `${contenu.slice(0, 80)}…` : contenu;
    const donnees = { publicationId, commentaireId };

    if (auteurParentId && auteurParentId !== auteurId) {
      await this.notificateur.notifier({
        utilisateurId: auteurParentId,
        type: 'SOCIAL',
        titre: 'Nouvelle réponse',
        contenu: `${nom} a répondu : ${extrait}`,
        donnees,
      });
    }
    // Mentionnés (hors auteur et personnes déjà notifiées ci-dessus/ci-dessous)
    for (const id of mentionnes) {
      if (id === auteurId || id === auteurParentId || id === vendeurId) continue;
      await this.notificateur.notifier({
        utilisateurId: id,
        type: 'SOCIAL',
        titre: 'Vous avez été mentionné',
        contenu: `${nom} vous a mentionné : ${extrait}`,
        donnees,
      });
    }

    if (vendeurId !== auteurId && vendeurId !== auteurParentId) {
      await this.notificateur.notifier({
        utilisateurId: vendeurId,
        type: 'SOCIAL',
        titre: 'Nouveau commentaire',
        contenu: `${nom} a commenté : ${extrait}`,
        donnees,
      });
    }
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
