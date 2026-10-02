import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { NotificationService } from '../../auth/services/notification.service.js';
import { DecisionKyc } from '../dto/decision-admin.dto.js';
import type { DecisionAdminDto } from '../dto/decision-admin.dto.js';

@Injectable()
export class DecisionAdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationService: NotificationService,
  ) {}

  async executer(
    dossierKycId: string,
    adminId: string,
    dto: DecisionAdminDto,
  ) {
    if (dto.decision === DecisionKyc.REJETE && !dto.motifRejet) {
      throw new BadRequestException(
        'Un motif de rejet est obligatoire.',
      );
    }

    const dossier = await this.prisma.dossierKyc.findUnique({
      where: { id: dossierKycId },
      select: {
        id: true,
        statut: true,
        vendeurId: true,
        vendeur: {
          select: {
            utilisateur: {
              select: {
                id: true,
                telephone: true,
                email: true,
              },
            },
          },
        },
      },
    });

    if (!dossier) throw new NotFoundException('Dossier KYC introuvable.');

    if (dossier.statut !== 'EN_ATTENTE_REVUE_ADMIN') {
      throw new BadRequestException(
        'Ce dossier n\'est pas en attente de révision admin.',
      );
    }

    const maintenant = new Date();
    const estValide = dto.decision === DecisionKyc.VALIDE;

    // Transaction : mise à jour dossier + vendeur + revue admin
    await this.prisma.$transaction([
      // Mise à jour du dossier KYC
      this.prisma.dossierKyc.update({
        where: { id: dossierKycId },
        data: {
          statut: estValide ? 'VALIDE' : 'REJETE',
          dateValidation: estValide ? maintenant : null,
          dateRejet: estValide ? null : maintenant,
          motifRejet: dto.motifRejet ?? null,
        },
      }),

      // Mise à jour du statut vendeur
      this.prisma.vendeur.update({
        where: { id: dossier.vendeurId },
        data: {
          statutVendeur: estValide ? 'ACTIF' : 'SUSPENDU',
        },
      }),

      // Mise à jour du statut compte utilisateur si validé
      ...(estValide
        ? [
            this.prisma.utilisateur.update({
              where: { id: dossier.vendeur.utilisateur.id },
              data: { statutCompte: 'ACTIF' },
            }),
          ]
        : []),

      // Enregistrement de la revue admin
      this.prisma.revueKyc.create({
        data: {
          dossierKycId,
          administrateurId: adminId,
          statut: estValide ? 'VALIDE' : 'REJETE',
          commentaire: dto.motifRejet ?? null,
        },
      }),

      // Audit
      this.prisma.journalAudit.create({
        data: {
          administrateurId: adminId,
          action: estValide ? 'VALIDER_KYC' : 'REJETER_KYC',
          resourceType: 'DossierKyc',
          resourceId: dossierKycId,
          details: dto.motifRejet ? { motif: dto.motifRejet } : undefined,
        },
      }),
    ]);

    // Notification au vendeur
    const utilisateur = dossier.vendeur.utilisateur;
    const canal = utilisateur.email ? 'EMAIL' : 'SMS';
    const destination = canal === 'EMAIL'
      ? utilisateur.email!
      : utilisateur.telephone!;

    // On réutilise NotificationService pour pousser dans la queue
    await this.notificationService.envoyerOtp({
      destination,
      canal,
      code: estValide
        ? 'Votre dossier KYC a été validé. Vous pouvez maintenant vendre sur DROPP !'
        : `Votre dossier KYC a été rejeté. Motif : ${dto.motifRejet}`,
      type: 'verification',
    });

    return {
      statut: estValide ? 'VALIDE' : 'REJETE',
      message: estValide
        ? 'Dossier validé. Le vendeur est maintenant actif.'
        : 'Dossier rejeté.',
    };
  }
}