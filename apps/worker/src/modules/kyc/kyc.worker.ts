import { Logger } from '@nestjs/common';
import { Processor, WorkerHost } from '@nestjs/bullmq';
import type { Job } from 'bullmq';

import {
  JOB_KYC,
  QUEUE_KYC,
  type JobVerifierVisageKyc,
} from '@dropp/contrats';

import { FaceMatchService } from './services/face-match.service.js';
import { PrismaService } from '../../infrastructure/database/database/prisma.service.js';

const SEUIL_FACE_MATCH = 0.75; // Score minimum pour passer en revue admin

@Processor(QUEUE_KYC)
export class KycWorker extends WorkerHost {
  private readonly logger = new Logger(KycWorker.name);

  constructor(
    private readonly faceMatch: FaceMatchService, 
    private readonly prisma: PrismaService
  ) { super(); }

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
    const { dossierKycId, vendeurId, cleStockageSelfie, cleStockageCniRecto } =
      job.data;

    this.logger.log(`Vérification faciale dossier ${dossierKycId}`);

    try {
      const resultat = await this.faceMatch.comparer(
        cleStockageSelfie,
        cleStockageCniRecto,
      );

      // Enregistrement de la vérification
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

      if (resultat.score >= SEUIL_FACE_MATCH) {
        // Score suffisant → attente revue admin
        await this.prisma.dossierKyc.update({
          where: { id: dossierKycId },
          data: {
            statut: 'EN_ATTENTE_REVUE_ADMIN',
            scoreFaceMatch: resultat.score,
          },
        });

        this.logger.log(
          `Dossier ${dossierKycId} : score ${resultat.score} ≥ seuil → EN_ATTENTE_REVUE_ADMIN`,
        );
      } else {
        // Score insuffisant → rejet automatique avec possibilité de renvoyer
        await this.prisma.dossierKyc.update({
          where: { id: dossierKycId },
          data: {
            statut: 'EN_ATTENTE',
            scoreFaceMatch: resultat.score,
            motifRejet: `Score de correspondance faciale insuffisant (${Math.round(resultat.score * 100)}%). Veuillez reprendre le selfie dans de meilleures conditions.`,
          },
        });

        this.logger.warn(
          `Dossier ${dossierKycId} : score ${resultat.score} < seuil → renvoyé en EN_ATTENTE`,
        );
      }
    } catch (erreur) {
      this.logger.error(
        `Erreur vérification faciale dossier ${dossierKycId} : ${String(erreur)}`,
      );

      // En cas d'erreur technique : repasser en attente pour retry BullMQ
      await this.prisma.dossierKyc.update({
        where: { id: dossierKycId },
        data: { statut: 'EN_ATTENTE' },
      });

      throw erreur; // BullMQ retentera selon la config (3 tentatives)
    }
  }
}