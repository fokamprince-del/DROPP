import {
  Injectable,
} from '@nestjs/common';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { NotificationService } from '../../auth/services/notification.service.js';
import { NotificateurService } from '../../notifications/notificateur.service.js';
import { DecisionKyc, type DecisionAdminDto } from '../dto/decision-admin.dto.js';
import { DroppException } from '../../../infrastructure/http/droppException.js';
import { KYC_ERRORS } from '@dropp/contrats';

@Injectable()
export class DecisionAdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationService: NotificationService,
    private readonly notificateur: NotificateurService,
  ) {}

  /**
   * Validation : le vendeur devient ACTIF et peut créer sa boutique.
   * Rejet : le dossier repasse en REJETE, le vendeur reste EN_ATTENTE_VALIDATION
   * et peut corriger ses pièces puis resoumettre.
   * Le statut du COMPTE n'est jamais modifié ici (un compte suspendu le reste).
   */
  async executer(dossierKycId: string, adminId: string, dto: DecisionAdminDto) {
    const estValide = dto.decision === DecisionKyc.VALIDE;
    if (!estValide && !dto.motifRejet) {
      throw  DroppException.BadRequest('Un motif de rejet est obligatoire.', KYC_ERRORS.REJECTION_REASON_REQUIRED);
    }

    const dossier = await this.prisma.dossierKyc.findUnique({
      where: { id: dossierKycId },
      select: {
        statut: true,
        vendeurId: true,
        vendeur: {
          select: {
            statutVendeur: true,
            utilisateur: { select: { telephone: true, email: true, emailVerifieLe: true } },
          },
        },
      },
    });
    if (!dossier) throw DroppException.NotFound('Dossier KYC introuvable.', KYC_ERRORS.KYC_DOSSIER_NOT_FOUND);
    if (dossier.statut !== 'EN_ATTENTE_REVUE_ADMIN') {
      throw DroppException.BadRequest(
        'Ce dossier n’est pas en attente de révision admin.',
        KYC_ERRORS.KYC_NOT_PENDING_ADMIN_REVIEW 
      );
    }

    const maintenant = new Date();
    await this.prisma.$transaction(async (tx) => {
      // Garde atomique : deux administrateurs ne décident pas en même temps.
      const { count } = await tx.dossierKyc.updateMany({
        where: { id: dossierKycId, statut: 'EN_ATTENTE_REVUE_ADMIN' },
        data: {
          statut: estValide ? 'VALIDE' : 'REJETE',
          dateValidation: estValide ? maintenant : null,
          dateRejet: estValide ? null : maintenant,
          motifRejet: estValide ? null : dto.motifRejet,
        },
      });
      if (count === 0) {
        throw DroppException.Conflict('Une décision a déjà été prise sur ce dossier.', KYC_ERRORS.KYC_DECISION_ALREADY_MADE);
      }

      await tx.documentKyc.updateMany({
        where: { dossierKycId },
        data: { statut: estValide ? 'VALIDE' : 'REJETE' },
      });

      // Un vendeur suspendu par l'administration n'est pas réactivé par le KYC.
      if (estValide && dossier.vendeur.statutVendeur === 'EN_ATTENTE_VALIDATION') {
        await tx.vendeur.update({
          where: { id: dossier.vendeurId },
          data: { statutVendeur: 'ACTIF' },
        });
      }

      await tx.revueKyc.create({
        data: {
          dossierKycId,
          administrateurId: adminId,
          statut: estValide ? 'VALIDE' : 'REJETE',
          commentaire: dto.motifRejet ?? null,
        },
      });

      await tx.journalAudit.create({
        data: {
          administrateurId: adminId,
          action: estValide ? 'VALIDER_KYC' : 'REJETER_KYC',
          resourceType: 'DossierKyc',
          resourceId: dossierKycId,
          details: dto.motifRejet ? { motif: dto.motifRejet } : undefined,
        },
      });
    });

    const titre = estValide ? 'Identité vérifiée' : 'Vérification d’identité refusée';
    const message = estValide
      ? 'Votre identité a été vérifiée. Vous pouvez maintenant créer votre boutique et vendre sur DROPP.'
      : `Votre vérification d’identité a été refusée. Motif : ${dto.motifRejet}. Corrigez vos documents puis soumettez à nouveau votre dossier.`;

    void this.notificateur.notifier({
      utilisateurId: dossier.vendeurId,
      type: 'SYSTEME',
      titre,
      contenu: message,
      donnees: { dossierKycId },
    });

    const { email, emailVerifieLe, telephone } = dossier.vendeur.utilisateur;
    const destination = email && emailVerifieLe ? email : telephone;
    if (destination) {
      await this.notificationService.envoyerMessage({
        destination,
        canal: destination === email ? 'EMAIL' : 'SMS',
        sujet: titre,
        message,
      });
    }

    return {
      statut: estValide ? 'VALIDE' : 'REJETE',
      message: estValide
        ? 'Dossier validé. Le vendeur est maintenant actif.'
        : 'Dossier rejeté.',
    };
  }
}
