import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import type { ActionModeration } from '@dropp/database';

export class TraiterSignalementDto {
  action!: ActionModeration;
  commentaire?: string;
}

@Injectable()
export class TraiterSignalementService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(
    signalementId: string,
    adminId: string,
    dto: TraiterSignalementDto,
  ) {
    const signalement = await this.prisma.signalement.findUnique({
      where: { id: signalementId },
      select: {
        id: true,
        statut: true,
        publicationId: true,
        commentaireId: true,
        produitId: true,
      },
    });

    if (!signalement) throw new NotFoundException('Signalement introuvable.');

    if (signalement.statut === 'TRAITE' || signalement.statut === 'REJETE') {
      throw new BadRequestException('Ce signalement a déjà été traité.');
    }

    await this.prisma.$transaction(async (tx) => {
      // Mettre à jour le signalement
      await tx.signalement.update({
        where: { id: signalementId },
        data: { statut: 'TRAITE' },
      });

      // Créer le dossier de modération
      await tx.dossierModeration.create({
        data: {
          administrateurId: adminId,
          statut: 'CLOTURE',
          action: dto.action,
          dateCloture: new Date(),
        },
      });

      // Appliquer l'action
      if (dto.action === 'MASQUER' || dto.action === 'SUPPRIMER') {
        if (signalement.publicationId) {
          await tx.publication.update({
            where: { id: signalement.publicationId },
            data: {
              statut: dto.action === 'MASQUER' ? 'PROCESSING' : 'SUPPRIMEE',
            },
          });
        }

        if (signalement.commentaireId) {
          await tx.commentaire.update({
            where: { id: signalement.commentaireId },
            data: {
              statut: dto.action === 'MASQUER'
                ? 'MASQUE_MODERATION'
                : 'SUPPRIME',
            },
          });
        }

        if (signalement.produitId) {
          await tx.produit.update({
            where: { id: signalement.produitId },
            data: {
              statut: dto.action === 'MASQUER' ? 'PROCESSING' : 'ARCHIVE',
            },
          });
        }
      }

      await tx.journalAudit.create({
        data: {
          administrateurId: adminId,
          action: 'TRAITER_SIGNALEMENT',
          resourceType: 'Signalement',
          resourceId: signalementId,
          details: { action: dto.action, commentaire: dto.commentaire },
        },
      });
    });

    return { signalementId, action: dto.action, statut: 'TRAITE' };
  }
}