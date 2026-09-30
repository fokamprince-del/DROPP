import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import {
  StatutConversation,
  StatutMessage,
  StatutTraitementMedia,
  TypeMedia,
  TypeMessage,
  TypeNotification,
} from '../../generated/prisma/enums.js';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { EVENEMENT } from '../../infrastructure/realtime/evenements.js';
import { RealtimeService } from '../../infrastructure/realtime/realtime.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../infrastructure/stockage/stockage-provider.contract.js';
import { verifierUpload } from '../../infrastructure/stockage/verifier-upload.js';
import { NotificateurService } from '../notifications/notificateur.service.js';
import { BlocagesService } from './blocages.service.js';
import {
  TAILLE_MAX_PIECE_JOINTE,
  type EnvoyerMessageDto,
  type SignaturePieceJointeDto,
} from './dto/messagerie.dto.js';
import { nomAffiche, profilPublicSelection } from './presentation.js';

const messageSelection = {
  id: true,
  conversationId: true,
  expediteurId: true,
  contenu: true,
  type: true,
  statut: true,
  dateCreation: true,
  piecesJointes: {
    select: {
      id: true,
      type: true,
      media: {
        select: {
          cleStockage: true,
          typeMime: true,
          taille: true,
          largeur: true,
          hauteur: true,
          duree: true,
          statutTraitement: true,
        },
      },
    },
  },
} as const;

type MessageBrut = {
  id: string;
  conversationId: string;
  expediteurId: string;
  contenu: string | null;
  type: TypeMessage;
  statut: StatutMessage;
  dateCreation: Date;
  piecesJointes: {
    id: string;
    type: TypeMedia;
    media: {
      cleStockage: string;
      typeMime: string;
      taille: bigint;
      largeur: number | null;
      hauteur: number | null;
      duree: number | null;
      statutTraitement: StatutTraitementMedia;
    };
  }[];
};

@Injectable()
export class MessagesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly blocages: BlocagesService,
    private readonly realtime: RealtimeService,
    private readonly notificateur: NotificateurService,
    @Inject(STOCKAGE_PROVIDER) private readonly stockage: StockageProvider,
  ) {}

  /** Pagination par curseur : `avant` = id du plus ancien message déjà affiché. */
  async lister(
    utilisateurId: string,
    conversationId: string,
    avant: string | undefined,
    limite: number,
  ) {
    await this.participantsOuErreur(utilisateurId, conversationId);

    const messages = await this.prisma.message.findMany({
      where: { conversationId },
      orderBy: [{ dateCreation: 'desc' }, { id: 'desc' }],
      take: limite,
      ...(avant && { cursor: { id: avant }, skip: 1 }),
      select: messageSelection,
    });

    return {
      donnees: await Promise.all(messages.map((m) => this.presenter(m))),
      curseurSuivant:
        messages.length === limite ? messages[messages.length - 1].id : null,
    };
  }

  async signaturePieceJointe(
    utilisateurId: string,
    conversationId: string,
    dto: SignaturePieceJointeDto,
  ) {
    const participants = await this.participantsOuErreur(
      utilisateurId,
      conversationId,
    );
    await this.verifierPeutEcrire(utilisateurId, conversationId, participants);

    const tailleMax = TAILLE_MAX_PIECE_JOINTE[dto.typeMime];
    if (dto.taille > tailleMax * 1024 * 1024) {
      throw new BadRequestException(
        `Fichier trop volumineux. Maximum : ${tailleMax} Mo pour ce type.`,
      );
    }
    return this.stockage.genererSignatureUpload(
      this.repertoire(conversationId, utilisateurId),
      dto.typeMime,
      tailleMax,
    );
  }

  async envoyer(
    utilisateurId: string,
    conversationId: string,
    dto: EnvoyerMessageDto,
  ) {
    const pieces = dto.piecesJointes ?? [];
    if (!dto.contenu && pieces.length === 0) {
      throw new BadRequestException('Le message est vide.');
    }

    const participants = await this.participantsOuErreur(
      utilisateurId,
      conversationId,
    );
    await this.verifierPeutEcrire(utilisateurId, conversationId, participants);

    // Les fichiers doivent avoir été uploadés par l'expéditeur dans cette
    // conversation, et respecter les limites (taille réelle, pas déclarée).
    const tailles: number[] = [];
    for (const piece of pieces) {
      const reel = await verifierUpload(this.stockage, {
        cleStockage: piece.cleStockage,
        prefixe: this.repertoire(conversationId, utilisateurId),
        tailleMaxMo: TAILLE_MAX_PIECE_JOINTE[piece.typeMime],
        typesMime: [piece.typeMime],
      });
      tailles.push(reel.taille);
    }

    const typesMedia = pieces.map((p) =>
      p.typeMime.startsWith('video/') ? TypeMedia.VIDEO : TypeMedia.IMAGE,
    );
    const type =
      pieces.length === 0
        ? TypeMessage.TEXTE
        : typesMedia.every((t) => t === TypeMedia.IMAGE)
          ? TypeMessage.IMAGE
          : typesMedia.every((t) => t === TypeMedia.VIDEO)
            ? TypeMessage.VIDEO
            : TypeMessage.FICHIER;

    const message = await this.prisma.$transaction(async (tx) => {
      const cree = await tx.message.create({
        data: {
          conversationId,
          expediteurId: utilisateurId,
          contenu: dto.contenu || null,
          type,
          piecesJointes: {
            create: pieces.map((p, i) => ({
              type: typesMedia[i],
              media: {
                create: {
                  typeMedia: typesMedia[i],
                  cleStockage: p.cleStockage,
                  typeMime: p.typeMime,
                  taille: tailles[i],
                  largeur: p.largeur,
                  hauteur: p.hauteur,
                  duree: p.duree,
                  // Pas de transcodage pour les pièces jointes : lues telles quelles.
                  statutTraitement: StatutTraitementMedia.PRET,
                },
              },
            })),
          },
        },
        select: messageSelection,
      });
      await tx.conversation.update({
        where: { id: conversationId },
        data: { dateDerniereActivite: cree.dateCreation },
      });
      return cree;
    });

    const presente = await this.presenter(message);
    // Tous les participants, expéditeur compris (ses autres appareils).
    this.realtime.emettre(
      participants.map((p) => p.utilisateurId),
      EVENEMENT.MESSAGE_NOUVEAU,
      presente,
    );
    void this.notifierDestinataires(utilisateurId, participants, message);

    return presente;
  }

  /** Accusé de lecture : tous les messages reçus de la conversation passent LU. */
  async marquerLus(utilisateurId: string, conversationId: string) {
    const participants = await this.participantsOuErreur(
      utilisateurId,
      conversationId,
    );
    const { count } = await this.prisma.message.updateMany({
      where: {
        conversationId,
        expediteurId: { not: utilisateurId },
        statut: StatutMessage.ENVOYE,
      },
      data: { statut: StatutMessage.LU },
    });

    if (count > 0) {
      this.realtime.emettre(
        participants
          .map((p) => p.utilisateurId)
          .filter((id) => id !== utilisateurId),
        EVENEMENT.MESSAGES_LUS,
        { conversationId, luPar: utilisateurId, dateLecture: new Date() },
      );
    }
    return { conversationId, messagesLus: count };
  }

  private async participantsOuErreur(
    utilisateurId: string,
    conversationId: string,
  ) {
    const participants = await this.prisma.participantConversation.findMany({
      where: { conversationId },
      select: { utilisateurId: true },
    });
    if (!participants.some((p) => p.utilisateurId === utilisateurId)) {
      throw new NotFoundException('Conversation introuvable.');
    }
    return participants;
  }

  private async verifierPeutEcrire(
    utilisateurId: string,
    conversationId: string,
    participants: { utilisateurId: string }[],
  ) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      select: { statut: true },
    });
    if (conversation?.statut !== StatutConversation.ACTIVE) {
      throw new ForbiddenException('Cette conversation est fermée.');
    }
    for (const p of participants) {
      if (p.utilisateurId === utilisateurId) continue;
      if (await this.blocages.estBloque(utilisateurId, p.utilisateurId)) {
        throw new ForbiddenException(
          'Impossible d’envoyer un message à cet utilisateur.',
        );
      }
    }
  }

  private async notifierDestinataires(
    utilisateurId: string,
    participants: { utilisateurId: string }[],
    message: MessageBrut,
  ) {
    const expediteur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: profilPublicSelection,
    });
    if (!expediteur) return;

    const apercu =
      message.contenu?.slice(0, 120) ??
      (message.type === TypeMessage.IMAGE
        ? '📷 Photo'
        : message.type === TypeMessage.VIDEO
          ? '🎥 Vidéo'
          : '📎 Pièce jointe');

    for (const p of participants) {
      if (p.utilisateurId === utilisateurId) continue;
      await this.notificateur.notifier({
        utilisateurId: p.utilisateurId,
        type: TypeNotification.MESSAGE,
        titre: nomAffiche(expediteur),
        contenu: apercu,
        donnees: {
          conversationId: message.conversationId,
          messageId: message.id,
        },
        persister: false,
      });
    }
  }

  private repertoire(conversationId: string, utilisateurId: string) {
    return `conversations/${conversationId}/${utilisateurId}`;
  }

  /** Pièces jointes privées : URL signées valables 1 h (l'app rafraîchit la liste au besoin). */
  private async presenter(m: MessageBrut) {
    const urls = await Promise.all(
      m.piecesJointes.map((pj) => this.stockage.urlSignee(pj.media.cleStockage, 3600)),
    );
    return {
      id: m.id,
      conversationId: m.conversationId,
      expediteurId: m.expediteurId,
      contenu: m.contenu,
      type: m.type,
      statut: m.statut,
      dateCreation: m.dateCreation,
      piecesJointes: m.piecesJointes.map((pj, i) => ({
        id: pj.id,
        type: pj.type,
        url: urls[i],
        typeMime: pj.media.typeMime,
        taille: Number(pj.media.taille),
        largeur: pj.media.largeur,
        hauteur: pj.media.hauteur,
        duree: pj.media.duree,
      })),
    };
  }
}
