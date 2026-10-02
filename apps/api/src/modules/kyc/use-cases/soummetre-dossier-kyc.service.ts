import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import type { Queue } from 'bullmq';
import {
  JOB_KYC,
  QUEUE_KYC,
  type JobVerifierVisageKyc,
} from '@dropp/contrats';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { TypeDocumentKyc } from '@dropp/database';

const DOCUMENTS_REQUIS: TypeDocumentKyc[] = [
  'CNI_RECTO',
  'CNI_VERSO',
  'PHOTO_FACIALE',
];

@Injectable()
export class SoumettreDoissierService {
  constructor(
    private readonly prisma: PrismaService,
    @InjectQueue(QUEUE_KYC) private readonly kycQueue: Queue,
  ) {}

  /**
   * Vérifie la complétude du dossier et déclenche la vérification faciale.
   */
  async executer(utilisateurId: string) {
    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: utilisateurId },
      select: {
        dossiersKyc: {
          orderBy: { dateSoumission: 'desc' },
          take: 1,
          select: {
            id: true,
            statut: true,
            nomLegal: true,
            prenomLegal: true,
            numeroCni: true,
            dateNaissance: true,
            lieuNaissance: true,
            dateEtablissement: true,
            dateExpiration: true,
            documents: {
              select: { typeDocument: true, cleStockage: true },
            },
          },
        },
      },
    });

    if (!vendeur) throw new ForbiddenException('Profil vendeur introuvable.');

    const dossier = vendeur.dossiersKyc[0];
    if (!dossier) throw new NotFoundException('Dossier KYC introuvable.');

    if (!['EN_ATTENTE', 'REJETE'].includes(dossier.statut)) {
      throw new BadRequestException('Ce dossier a déjà été soumis.');
    }

    // Vérifier que tous les documents sont présents
    const typesPresents = dossier.documents.map((d) => d.typeDocument);
    const manquants = DOCUMENTS_REQUIS.filter(
      (t) => !typesPresents.includes(t),
    );

    if (manquants.length > 0) {
      throw new BadRequestException(
        `Documents manquants : ${manquants.join(', ')}`,
      );
    }

    // Vérifier que les données CNI sont renseignées
    if (
      !dossier.nomLegal ||
      !dossier.prenomLegal ||
      !dossier.numeroCni ||
      !dossier.dateNaissance ||
      !dossier.dateExpiration
    ) {
      throw new BadRequestException(
        'Les données de la carte d\'identité sont incomplètes.',
      );
    }

    // Passer en cours de vérification
    await this.prisma.dossierKyc.update({
      where: { id: dossier.id },
      data: { statut: 'EN_COURS_VERIFICATION' },
    });

    // Déclencher la vérification faciale via BullMQ
    const selfie = dossier.documents.find((d) => d.typeDocument === 'PHOTO_FACIALE');
    const cniRecto = dossier.documents.find((d) => d.typeDocument === 'CNI_RECTO');

    await this.kycQueue.add(
      JOB_KYC.VERIFIER_VISAGE,
      {
        dossierKycId: dossier.id,
        vendeurId: utilisateurId,
        cleStockageSelfie: selfie!.cleStockage,
        cleStockageCniRecto: cniRecto!.cleStockage,
      } satisfies JobVerifierVisageKyc,
    );

    return {
      statut: 'EN_COURS_VERIFICATION',
      message: 'Dossier soumis. La vérification est en cours.',
    };
  }
}