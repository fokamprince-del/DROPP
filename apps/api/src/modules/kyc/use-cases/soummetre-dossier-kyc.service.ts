import { BadRequestException, ConflictException, Injectable } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import type { Queue } from 'bullmq';
import {
  JOB_KYC,
  QUEUE_KYC,
  type JobVerifierVisageKyc,
} from '@dropp/contrats';

import type { TypeDocumentKyc } from '@dropp/database';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { DossierKycService, STATUTS_MODIFIABLES } from '../services/dossier-kyc.service.js';
import { KycStockageService } from '../services/kyc-stockage.service.js';

const DOCUMENTS_REQUIS: TypeDocumentKyc[] = [
  'CNI_RECTO',
  'CNI_VERSO',
  'PHOTO_FACIALE',
];

/**
 * Durée des liens transmis au prestataire de vérification faciale : couvre
 * l'attente dans la file et les nouvelles tentatives du job.
 */
const DUREE_LIEN_VERIFICATION_S = 60 * 60;

@Injectable()
export class SoumettreDoissierService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly stockage: KycStockageService,
    private readonly dossiers: DossierKycService,
    @InjectQueue(QUEUE_KYC) private readonly kycQueue: Queue,
  ) {}

  /** Vérifie la complétude du dossier et déclenche la vérification faciale. */
  async executer(utilisateurId: string) {
    const { id } = await this.dossiers.modifiable(utilisateurId);
    const dossier = await this.prisma.dossierKyc.findUniqueOrThrow({
      where: { id },
      select: {
        id: true,
        nomLegal: true,
        prenomLegal: true,
        numeroCni: true,
        dateNaissance: true,
        lieuNaissance: true,
        dateEtablissement: true,
        dateExpiration: true,
        documents: { select: { typeDocument: true, cleStockage: true } },
      },
    });

    const cle = (type: TypeDocumentKyc) =>
      dossier.documents.find((d) => d.typeDocument === type)?.cleStockage;
    const manquants = DOCUMENTS_REQUIS.filter((t) => !cle(t));
    if (manquants.length > 0) {
      throw new BadRequestException(
        `Documents manquants : ${manquants.join(', ')}`,
      );
    }

    if (
      !dossier.nomLegal ||
      !dossier.prenomLegal ||
      !dossier.numeroCni ||
      !dossier.dateNaissance ||
      !dossier.lieuNaissance ||
      !dossier.dateEtablissement ||
      !dossier.dateExpiration
    ) {
      throw new BadRequestException(
        'Les données de la carte d’identité sont incomplètes.',
      );
    }
    if (dossier.dateExpiration < new Date()) {
      throw new BadRequestException('Votre carte d’identité est expirée.');
    }

    // Passage conditionnel : une double soumission ne lance qu'une vérification.
    const { count } = await this.prisma.dossierKyc.updateMany({
      where: { id: dossier.id, statut: { in: STATUTS_MODIFIABLES } },
      data: {
        statut: 'EN_COURS_VERIFICATION',
        consentementLe: new Date(),
        motifRejet: null,
        dateRejet: null,
        dateSoumission: new Date(),
      },
    });
    if (count === 0) {
      throw new ConflictException('Ce dossier a déjà été soumis.');
    }

    const [urlSelfie, urlCniRecto] = await Promise.all([
      this.stockage.urlConsultation(cle('PHOTO_FACIALE')!, DUREE_LIEN_VERIFICATION_S),
      this.stockage.urlConsultation(cle('CNI_RECTO')!, DUREE_LIEN_VERIFICATION_S),
    ]);

    try {
      await this.kycQueue.add(
        JOB_KYC.VERIFIER_VISAGE,
        {
          dossierKycId: dossier.id,
          vendeurId: utilisateurId,
          urlSelfie,
          urlCniRecto,
        } satisfies JobVerifierVisageKyc,
        { jobId: `kyc-visage-${dossier.id}-${Date.now()}` },
      );
    } catch (erreur) {
      // File indisponible : le dossier redevient modifiable pour réessayer.
      await this.prisma.dossierKyc.update({
        where: { id: dossier.id },
        data: { statut: 'EN_ATTENTE' },
      });
      throw erreur;
    }

    return {
      statut: 'EN_COURS_VERIFICATION',
      message: 'Dossier soumis. La vérification est en cours.',
    };
  }
}
