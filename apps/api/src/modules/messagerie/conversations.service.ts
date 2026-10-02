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
  TypeConversation,
  type Prisma,
} from '@dropp/database';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../infrastructure/stockage/stockage-provider.contract.js';
import { BlocagesService } from './blocages.service.js';
import { presenterProfil, profilPublicSelection } from './presentation.js';

const conversationSelection = {
  id: true,
  type: true,
  statut: true,
  dateCreation: true,
  dateDerniereActivite: true,
  participants: {
    select: { utilisateur: { select: profilPublicSelection } },
  },
  messages: {
    orderBy: { dateCreation: 'desc' },
    take: 1,
    select: {
      id: true,
      expediteurId: true,
      contenu: true,
      type: true,
      statut: true,
      dateCreation: true,
    },
  },
} as const;

type ConversationBrute = Prisma.ConversationGetPayload<{
  select: typeof conversationSelection;
}>;

@Injectable()
export class ConversationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly blocages: BlocagesService,
    @Inject(STOCKAGE_PROVIDER) private readonly stockage: StockageProvider,
  ) {}

  /**
   * Retourne la conversation directe existante avec le destinataire, ou la crée.
   *
   * Anti-spam marketplace : on peut toujours écrire à une boutique active ;
   * un vendeur ne peut ouvrir une conversation avec un client que si ce
   * client lui a déjà commandé. Une conversation existante reste accessible.
   */
  async ouvrir(utilisateurId: string, destinataireId: string) {
    if (utilisateurId === destinataireId) {
      throw new BadRequestException('Impossible de vous écrire à vous-même.');
    }

    const destinataire = await this.prisma.utilisateur.findUnique({
      where: { id: destinataireId },
      select: {
        statutCompte: true,
        vendeur: {
          select: {
            statutVendeur: true,
            boutique: { select: { statut: true } },
          },
        },
      },
    });
    if (!destinataire || destinataire.statutCompte !== 'ACTIF') {
      throw new NotFoundException('Utilisateur introuvable.');
    }
    if (await this.blocages.estBloque(utilisateurId, destinataireId)) {
      throw new ForbiddenException('Impossible de contacter cet utilisateur.');
    }

    const existante = await this.trouverDirecte(utilisateurId, destinataireId);
    if (existante) return this.detail(utilisateurId, existante.id);

    const estBoutiqueActive =
      destinataire.vendeur?.statutVendeur === 'ACTIF' &&
      destinataire.vendeur.boutique?.statut === 'ACTIVE';
    if (!estBoutiqueActive) {
      const aCommande = await this.prisma.sousCommande.count({
        where: {
          vendeurId: utilisateurId,
          commande: { utilisateurId: destinataireId },
        },
      });
      if (aCommande === 0) {
        throw new ForbiddenException(
          'Vous ne pouvez contacter que des boutiques ou vos clients.',
        );
      }
    }

    const conversationId = await this.prisma.$transaction(async (tx) => {
      // Verrou sur la paire d'utilisateurs : deux ouvertures simultanées
      // ne doivent pas créer deux conversations.
      const cle = [utilisateurId, destinataireId].sort().join(':');
      await tx.$queryRaw`SELECT 1 FROM (SELECT pg_advisory_xact_lock(hashtext(${cle}))) AS verrou`;

      const dejaCreee = await tx.conversation.findFirst({
        where: this.filtreDirecte(utilisateurId, destinataireId),
        select: { id: true },
      });
      if (dejaCreee) return dejaCreee.id;

      const creee = await tx.conversation.create({
        data: {
          type: TypeConversation.DIRECTE,
          participants: {
            create: [
              { utilisateurId },
              { utilisateurId: destinataireId },
            ],
          },
        },
        select: { id: true },
      });
      return creee.id;
    });

    return this.detail(utilisateurId, conversationId);
  }

  /** Conversations ayant au moins un message, triées par activité. */
  async lister(utilisateurId: string, page: number, limite: number) {
    const where = {
      participants: { some: { utilisateurId } },
      messages: { some: {} },
    };
    const [conversations, total] = await this.prisma.$transaction([
      this.prisma.conversation.findMany({
        where,
        orderBy: { dateDerniereActivite: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
        select: conversationSelection,
      }),
      this.prisma.conversation.count({ where }),
    ]);

    const nonLus = await this.compterNonLus(
      utilisateurId,
      conversations.map((c) => c.id),
    );

    return {
      donnees: conversations.map((c) =>
        this.presenter(utilisateurId, c, nonLus.get(c.id) ?? 0),
      ),
      total,
      page,
      limite,
    };
  }

  async detail(utilisateurId: string, conversationId: string) {
    const conversation = await this.chargerConversation(conversationId);
    if (
      !conversation ||
      !conversation.participants.some((p) => p.utilisateur.id === utilisateurId)
    ) {
      throw new NotFoundException('Conversation introuvable.');
    }
    const nonLus = await this.compterNonLus(utilisateurId, [conversationId]);
    return this.presenter(
      utilisateurId,
      conversation,
      nonLus.get(conversationId) ?? 0,
    );
  }

  /** Badge global de la messagerie. */
  async totalNonLus(utilisateurId: string) {
    const nonLus = await this.prisma.message.count({
      where: {
        statut: StatutMessage.ENVOYE,
        expediteurId: { not: utilisateurId },
        conversation: { participants: { some: { utilisateurId } } },
      },
    });
    return { nonLus };
  }

  chargerConversation(conversationId: string): Promise<ConversationBrute | null> {
    return this.prisma.conversation.findUnique({
      where: { id: conversationId },
      select: conversationSelection,
    });
  }

  private async trouverDirecte(a: string, b: string) {
    return this.prisma.conversation.findFirst({
      where: this.filtreDirecte(a, b),
      select: { id: true },
    });
  }

  private filtreDirecte(a: string, b: string) {
    return {
      type: TypeConversation.DIRECTE,
      AND: [
        { participants: { some: { utilisateurId: a } } },
        { participants: { some: { utilisateurId: b } } },
      ],
    };
  }

  private async compterNonLus(utilisateurId: string, ids: string[]) {
    if (ids.length === 0) return new Map<string, number>();
    const groupes = await this.prisma.message.groupBy({
      by: ['conversationId'],
      where: {
        conversationId: { in: ids },
        expediteurId: { not: utilisateurId },
        statut: StatutMessage.ENVOYE,
      },
      _count: { _all: true },
    });
    return new Map(groupes.map((g) => [g.conversationId, g._count._all]));
  }

  private presenter(
    utilisateurId: string,
    c: NonNullable<ConversationBrute>,
    nonLus: number,
  ) {
    const interlocuteur = c.participants.find(
      (p) => p.utilisateur.id !== utilisateurId,
    );
    return {
      id: c.id,
      statut: c.statut,
      peutEcrire: c.statut === StatutConversation.ACTIVE,
      dateDerniereActivite: c.dateDerniereActivite,
      interlocuteur: interlocuteur
        ? presenterProfil(this.stockage, interlocuteur.utilisateur)
        : null,
      dernierMessage: c.messages[0] ?? null,
      nonLus,
    };
  }
}
