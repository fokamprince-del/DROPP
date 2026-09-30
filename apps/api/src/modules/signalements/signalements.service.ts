import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import type { Prisma } from '../../generated/prisma/client.js';
import {
  PrioriteSignalement,
  StatutSignalement,
} from '../../generated/prisma/enums.js';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import {
  MOTIFS,
  type CreerSignalementDto,
  type Motif,
  type TypeCible,
} from './dto/creer-signalement.dto.js';

const PRIORITE_PAR_MOTIF: Record<Motif, PrioriteSignalement> = {
  SPAM: PrioriteSignalement.BASSE,
  ARNAQUE: PrioriteSignalement.HAUTE,
  CONTREFACON: PrioriteSignalement.NORMALE,
  PRODUIT_INTERDIT: PrioriteSignalement.HAUTE,
  CONTENU_INAPPROPRIE: PrioriteSignalement.NORMALE,
  HARCELEMENT: PrioriteSignalement.HAUTE,
  VIOLENCE_HAINE: PrioriteSignalement.HAUTE,
  FAUSSE_INFORMATION: PrioriteSignalement.NORMALE,
  AUTRE: PrioriteSignalement.NORMALE,
};

const ORDRE_PRIORITE: PrioriteSignalement[] = [
  PrioriteSignalement.BASSE,
  PrioriteSignalement.NORMALE,
  PrioriteSignalement.HAUTE,
  PrioriteSignalement.CRITIQUE,
];

/** Au-delà de ces volumes de signalements ouverts, la cible remonte en priorité. */
const SEUIL_HAUTE = 5;
const SEUIL_CRITIQUE = 10;

const STATUTS_OUVERTS = [StatutSignalement.OUVERT, StatutSignalement.EN_COURS];

const CHAMP_CIBLE = {
  PUBLICATION: 'publicationId',
  COMMENTAIRE: 'commentaireId',
  PRODUIT: 'produitId',
  BOUTIQUE: 'boutiqueId',
  MESSAGE: 'messageId',
} as const satisfies Record<TypeCible, keyof Prisma.SignalementWhereInput>;

@Injectable()
export class SignalementsService {
  constructor(private readonly prisma: PrismaService) {}

  listerMotifs() {
    return Object.entries(MOTIFS).map(([code, libelle]) => ({ code, libelle }));
  }

  async creer(utilisateurId: string, dto: CreerSignalementDto) {
    const proprietaireId = await this.proprietaireCible(
      utilisateurId,
      dto.typeCible,
      dto.cibleId,
    );
    if (proprietaireId === utilisateurId) {
      throw new BadRequestException(
        'Vous ne pouvez pas signaler votre propre contenu.',
      );
    }

    const champ = CHAMP_CIBLE[dto.typeCible];
    const filtreCible = { [champ]: dto.cibleId } as Prisma.SignalementWhereInput;

    const dejaSignale = await this.prisma.signalement.count({
      where: {
        ...filtreCible,
        utilisateurId,
        statut: { in: STATUTS_OUVERTS },
      },
    });
    if (dejaSignale > 0) {
      throw new ConflictException(
        'Vous avez déjà signalé ce contenu. Il est en cours d’examen.',
      );
    }

    const ouverts = await this.prisma.signalement.count({
      where: { ...filtreCible, statut: { in: STATUTS_OUVERTS } },
    });
    const total = ouverts + 1;
    let priorite = PRIORITE_PAR_MOTIF[dto.motif];
    if (total >= SEUIL_CRITIQUE) {
      priorite = PrioriteSignalement.CRITIQUE;
    } else if (total >= SEUIL_HAUTE) {
      priorite = this.max(priorite, PrioriteSignalement.HAUTE);
    }

    const [signalement] = await this.prisma.$transaction([
      this.prisma.signalement.create({
        data: {
          utilisateurId,
          [champ]: dto.cibleId,
          motif: dto.motif,
          description: dto.description,
          priorite,
        } as Prisma.SignalementUncheckedCreateInput,
        select: {
          id: true,
          motif: true,
          statut: true,
          dateCreation: true,
        },
      }),
      // Les signalements ouverts de la cible remontent tous au même niveau
      // pour que la file de modération la traite d'un bloc.
      this.prisma.signalement.updateMany({
        where: {
          ...filtreCible,
          statut: { in: STATUTS_OUVERTS },
          priorite: { in: ORDRE_PRIORITE.slice(0, ORDRE_PRIORITE.indexOf(priorite)) },
        },
        data: { priorite },
      }),
    ]);

    return {
      ...signalement,
      typeCible: dto.typeCible,
      cibleId: dto.cibleId,
      message: 'Merci. Notre équipe va examiner ce signalement.',
    };
  }

  async listerMiens(utilisateurId: string, page: number, limite: number) {
    const where = { utilisateurId };
    const [signalements, total] = await this.prisma.$transaction([
      this.prisma.signalement.findMany({
        where,
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
        select: {
          id: true,
          motif: true,
          description: true,
          statut: true,
          dateCreation: true,
          publicationId: true,
          commentaireId: true,
          produitId: true,
          boutiqueId: true,
          messageId: true,
        },
      }),
      this.prisma.signalement.count({ where }),
    ]);

    return {
      donnees: signalements.map((s) => {
        const [typeCible, cibleId] =
          (Object.entries(CHAMP_CIBLE) as [TypeCible, keyof typeof s][])
            .map(([type, champ]) => [type, s[champ]] as const)
            .find(([, id]) => id) ?? [null, null];
        return {
          id: s.id,
          motif: s.motif,
          libelleMotif: MOTIFS[s.motif as Motif] ?? s.motif,
          description: s.description,
          statut: s.statut,
          dateCreation: s.dateCreation,
          typeCible,
          cibleId,
        };
      }),
      total,
      page,
      limite,
    };
  }

  /** Vérifie que la cible existe (et est visible par l'émetteur) ; retourne son auteur. */
  private async proprietaireCible(
    utilisateurId: string,
    type: TypeCible,
    id: string,
  ): Promise<string> {
    switch (type) {
      case 'PUBLICATION': {
        const p = await this.prisma.publication.findUnique({
          where: { id },
          select: { boutiqueId: true, statut: true },
        });
        if (!p || p.statut === 'SUPPRIMEE') break;
        return p.boutiqueId;
      }
      case 'COMMENTAIRE': {
        const c = await this.prisma.commentaire.findUnique({
          where: { id },
          select: { utilisateurId: true, statut: true },
        });
        if (!c || c.statut !== 'VISIBLE') break;
        return c.utilisateurId;
      }
      case 'PRODUIT': {
        const p = await this.prisma.produit.findUnique({
          where: { id },
          select: { boutiqueId: true },
        });
        if (!p) break;
        return p.boutiqueId;
      }
      case 'BOUTIQUE': {
        const b = await this.prisma.boutique.findUnique({
          where: { id },
          select: { id: true },
        });
        if (!b) break;
        return b.id;
      }
      case 'MESSAGE': {
        // On ne peut signaler qu'un message d'une conversation dont on fait partie.
        const m = await this.prisma.message.findFirst({
          where: {
            id,
            conversation: { participants: { some: { utilisateurId } } },
          },
          select: { expediteurId: true },
        });
        if (!m) break;
        return m.expediteurId;
      }
    }
    throw new NotFoundException('Contenu introuvable.');
  }

  private max(a: PrioriteSignalement, b: PrioriteSignalement) {
    return ORDRE_PRIORITE.indexOf(a) >= ORDRE_PRIORITE.indexOf(b) ? a : b;
  }
}
