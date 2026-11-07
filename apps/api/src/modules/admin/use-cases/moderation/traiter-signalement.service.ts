import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Transform } from 'class-transformer';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

import { ActionModeration, type Prisma } from '@dropp/database';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import { NotificateurService } from '../../../notifications/notificateur.service.js';
import { verifierCibleAdministrable } from '../../protection-admin.js';
import { SuspendreUtilisateurService } from '../utilisateurs/suspendre-utilisateur.service.js';

export class TraiterSignalementDto {
  /**
   * AUCUNE : signalement fondé mais sans action · REJETER : non fondé ·
   * MASQUER : contenu retiré du public (réversible) · SUPPRIMER : contenu
   * supprimé · SUSPENDRE : contenu masqué + compte de l'auteur suspendu.
   */
  @IsEnum(ActionModeration)
  action!: ActionModeration;

  @IsOptional()
  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @MaxLength(1000)
  commentaire?: string;
}

const STATUTS_OUVERTS = ['OUVERT', 'EN_COURS'] as const;
const MESSAGE_RETIRE = 'Message retiré par la modération.';

type Cible = {
  publicationId: string | null;
  commentaireId: string | null;
  produitId: string | null;
  boutiqueId: string | null;
  messageId: string | null;
};

@Injectable()
export class TraiterSignalementService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly suspendreUtilisateur: SuspendreUtilisateurService,
    private readonly notificateur: NotificateurService,
  ) {}

  async executer(signalementId: string, adminId: string, dto: TraiterSignalementDto) {
    const signalement = await this.prisma.signalement.findUnique({
      where: { id: signalementId },
      select: {
        statut: true,
        publicationId: true,
        commentaireId: true,
        produitId: true,
        boutiqueId: true,
        messageId: true,
      },
    });
    if (!signalement) throw new NotFoundException('Signalement introuvable.');
    if (!(STATUTS_OUVERTS as readonly string[]).includes(signalement.statut)) {
      throw new BadRequestException('Ce signalement a déjà été traité.');
    }

    const auteurId = await this.auteurDuContenu(signalement);
    const suspendre = dto.action === ActionModeration.SUSPENDRE;
    if (suspendre) {
      if (!auteurId) throw new BadRequestException('Auteur du contenu introuvable.');
      await verifierCibleAdministrable(this.prisma, adminId, auteurId);
    }

    const statutFinal = dto.action === ActionModeration.REJETER ? 'REJETE' : 'TRAITE';
    // Tous les signalements ouverts sur la même cible sont clos ensemble.
    const filtreCible = this.filtreCible(signalement);
    const emetteurs = await this.prisma.signalement.findMany({
      where: { ...filtreCible, statut: { in: [...STATUTS_OUVERTS] } },
      select: { utilisateurId: true },
      distinct: ['utilisateurId'],
    });

    await this.prisma.$transaction(async (tx) => {
      await tx.signalement.updateMany({
        where: { ...filtreCible, statut: { in: [...STATUTS_OUVERTS] } },
        data: { statut: statutFinal },
      });

      await tx.dossierModeration.create({
        data: {
          administrateurId: adminId,
          statut: 'CLOTURE',
          action: dto.action,
          dateCloture: new Date(),
        },
      });

      const retrait =
        dto.action === ActionModeration.SUPPRIMER
          ? 'SUPPRIMER'
          : dto.action === ActionModeration.MASQUER || suspendre
            ? 'MASQUER'
            : null;
      if (retrait) await this.retirerContenu(tx, signalement, retrait);

      await tx.journalAudit.create({
        data: {
          administrateurId: adminId,
          action: 'TRAITER_SIGNALEMENT',
          resourceType: 'Signalement',
          resourceId: signalementId,
          details: {
            action: dto.action,
            commentaire: dto.commentaire ?? null,
            cible: filtreCible as Prisma.InputJsonObject,
          },
        },
      });
    });

    if (suspendre && auteurId) {
      const auteur = await this.prisma.utilisateur.findUnique({
        where: { id: auteurId },
        select: { statutCompte: true },
      });
      if (auteur?.statutCompte === 'ACTIF') {
        await this.suspendreUtilisateur.executer(
          auteurId,
          adminId,
          'SUSPENDU_TEMP',
          dto.commentaire ?? `Signalement ${signalementId}`,
        );
      }
    }

    for (const { utilisateurId } of emetteurs) {
      void this.notificateur.notifier({
        utilisateurId,
        type: 'SYSTEME',
        titre: 'Signalement examiné',
        contenu:
          statutFinal === 'REJETE'
            ? 'Après examen, le contenu que vous avez signalé ne contrevient pas à nos règles.'
            : 'Merci : le contenu que vous avez signalé a été examiné et traité par notre équipe.',
        cleDedoublonnage: `signalement:${utilisateurId}:${signalementId}`,
      });
    }

    return { signalementId, action: dto.action, statut: statutFinal };
  }

  /** Retire le contenu visé : MASQUER est réversible, SUPPRIMER non. */
  private async retirerContenu(
    tx: Prisma.TransactionClient,
    cible: Cible,
    mode: 'MASQUER' | 'SUPPRIMER',
  ) {
    const supprimer = mode === 'SUPPRIMER';
    if (cible.publicationId) {
      await tx.publication.update({
        where: { id: cible.publicationId },
        data: { statut: supprimer ? 'SUPPRIMEE' : 'REJETEE' },
      });
    }
    if (cible.commentaireId) {
      await tx.commentaire.update({
        where: { id: cible.commentaireId },
        data: { statut: supprimer ? 'SUPPRIME' : 'MASQUE_MODERATION' },
      });
    }
    if (cible.produitId) {
      // REJETE : le vendeur ne peut pas le republier lui-même.
      await tx.produit.update({
        where: { id: cible.produitId },
        data: { statut: supprimer ? 'ARCHIVE' : 'REJETE' },
      });
    }
    if (cible.boutiqueId) {
      // Boutique retirée = vendeur suspendu (réactivable par l'administration).
      await tx.vendeur.update({
        where: { id: cible.boutiqueId },
        data: { statutVendeur: 'SUSPENDU' },
      });
    }
    if (cible.messageId) {
      await tx.pieceJointeMessage.deleteMany({ where: { messageId: cible.messageId } });
      await tx.message.update({
        where: { id: cible.messageId },
        data: { contenu: MESSAGE_RETIRE, type: 'TEXTE' },
      });
    }
  }

  private async auteurDuContenu(cible: Cible): Promise<string | null> {
    if (cible.boutiqueId) return cible.boutiqueId;
    if (cible.publicationId) {
      const p = await this.prisma.publication.findUnique({
        where: { id: cible.publicationId },
        select: { boutiqueId: true },
      });
      return p?.boutiqueId ?? null;
    }
    if (cible.produitId) {
      const p = await this.prisma.produit.findUnique({
        where: { id: cible.produitId },
        select: { boutiqueId: true },
      });
      return p?.boutiqueId ?? null;
    }
    if (cible.commentaireId) {
      const c = await this.prisma.commentaire.findUnique({
        where: { id: cible.commentaireId },
        select: { utilisateurId: true },
      });
      return c?.utilisateurId ?? null;
    }
    if (cible.messageId) {
      const m = await this.prisma.message.findUnique({
        where: { id: cible.messageId },
        select: { expediteurId: true },
      });
      return m?.expediteurId ?? null;
    }
    return null;
  }

  private filtreCible(cible: Cible): Prisma.SignalementWhereInput {
    const champs = ['publicationId', 'commentaireId', 'produitId', 'boutiqueId', 'messageId'] as const;
    for (const champ of champs) {
      if (cible[champ]) return { [champ]: cible[champ] };
    }
    return { id: '00000000-0000-0000-0000-000000000000' };
  }
}
