import { Logger } from '@nestjs/common';
import { Processor, WorkerHost } from '@nestjs/bullmq';
import { InjectQueue } from '@nestjs/bullmq';
import { StatutKyc } from '@dropp/database';
import type { Job, Queue } from 'bullmq';

import {
  JOB_KYC,
  JOB_NOTIFICATION,
  QUEUE_KYC,
  QUEUE_NOTIFICATION,
  type JobVerifierVisageKyc,
  type JobNotificationSms,
  type JobNotificationEmail,
} from '@dropp/contrats';

import { PrismaService } from '../../infrastructure/database/database/prisma.service.js';
import { FaceMatchService } from './services/face-match.service.js';

const SEUIL_FACE_MATCH = 0.75;

@Processor(QUEUE_KYC)
export class KycWorker extends WorkerHost {
  private readonly logger = new Logger(KycWorker.name);

  constructor(
    private readonly faceMatch: FaceMatchService,
    private readonly prisma: PrismaService,
    @InjectQueue(QUEUE_NOTIFICATION)
    private readonly notificationQueue: Queue,
  ) {
    super();
  }

  async process(job: Job): Promise<void> {
    switch (job.name) {
      case JOB_KYC.VERIFIER_VISAGE:
        await this.verifierVisage(job as Job<JobVerifierVisageKyc>);
        break;
      default:
        this.logger.warn(`Job KYC inconnu : ${job.name}`);
    }
  }

  private async verifierVisage(
    job: Job<JobVerifierVisageKyc>,
  ): Promise<void> {
    const {
      dossierKycId,
      vendeurId,
      urlSelfie,
      urlCniRecto,
    } = job.data;

    this.logger.log(`Vérification faciale dossier ${dossierKycId}`);

    // Récupérer les informations de contact du vendeur
    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: vendeurId },
      select: {
        utilisateur: {
          select: { telephone: true, email: true },
        },
      },
    });

    try {

      // Face match
      const resultat = await this.faceMatch.comparer(
        urlSelfie,
        urlCniRecto,
      );

      // Enregistrer la vérification
      await this.prisma.verificationKyc.create({
        data: {
          dossierKycId,
          typeVerification: 'FACIALE',
          statut: resultat.correspondance ? 'VALIDE' : 'REJETE',
          scoreMatching: resultat.score,
          seuilDecision: SEUIL_FACE_MATCH,
          commentaire: resultat.details,
          dateVerification: new Date(),
        },
      });

      if (resultat.correspondance && resultat.score >= SEUIL_FACE_MATCH) {
        await this.prisma.dossierKyc.update({
          where: { id: dossierKycId },
          data: {
            statut: 'EN_ATTENTE_REVUE_ADMIN',
            scoreFaceMatch: resultat.score,
          },
        });

        await this.notifierVendeur(
          vendeur?.utilisateur,
          'Votre vérification faciale a réussi. Votre dossier est en cours de révision par notre équipe. Vous serez notifié dès qu\'une décision est prise.',
        );

        this.logger.log(
          `Dossier ${dossierKycId} → EN_ATTENTE_REVUE_ADMIN (score: ${resultat.score})`,
        );
      } else {
        await this.prisma.dossierKyc.update({
          where: { id: dossierKycId },
          data: {
            statut: StatutKyc.EN_ATTENTE,
            scoreFaceMatch: resultat.score,
            motifRejet: `Score de correspondance faciale insuffisant (${Math.round(resultat.score * 100)}%). Veuillez reprendre le selfie dans de meilleures conditions (bonne luminosité, visage bien visible).`,
          },
        });

        await this.notifierVendeur(
          vendeur?.utilisateur,
          `La vérification faciale n'a pas abouti (score: ${Math.round(resultat.score * 100)}%). Veuillez reprendre votre selfie dans de meilleures conditions et resoumettre votre dossier.`,
        );

        this.logger.warn(
          `Dossier ${dossierKycId} → EN_ATTENTE (score insuffisant: ${resultat.score})`,
        );
      }
    } catch (erreur) {
      this.logger.error(
        `Erreur vérification faciale dossier ${dossierKycId} : ${String(erreur)}`,
      );

      await this.prisma.dossierKyc.update({
        where: { id: dossierKycId },
        data: { statut: 'EN_ATTENTE' },
      });

      throw erreur;
    }
  }

  private async notifierVendeur(
    utilisateur: { telephone: string | null; email: string | null } | undefined,
    message: string,
  ): Promise<void> {
    if (!utilisateur) return;
    if (utilisateur.email) {
      await this.notificationQueue.add(JOB_NOTIFICATION.EMAIL, {
        destinataire: utilisateur.email,
        sujet: 'Mise à jour de votre dossier KYC - DROPP',
        corps: message,
      } satisfies JobNotificationEmail);
    } else if (utilisateur.telephone) {
      await this.notificationQueue.add(JOB_NOTIFICATION.SMS, {
        numero: utilisateur.telephone,
        message,
      } satisfies JobNotificationSms);
    }
  }
}
