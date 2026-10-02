import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { KycStockageService } from '../services/kyc-stockage.service.js';
import type { TypeDocumentKyc } from '@dropp/database';
import { DemanderSignatureDocumentKycDto, MAX_TAILLE_DOCUMENT_KYC, TYPES_MIME_KYC_AUTORISES } from '../dto/DemanderSignatureDocumentKyc.dto.js';
import { ConfirmerUploadDocumentKycDto } from '../dto/confirmer-upload-document-kyc.dto.js';



const TYPE_DOCUMENT_VERS_UPLOAD: Record<TypeDocumentKyc, 'cni-recto' | 'cni-verso' | 'selfie'> = {
  CNI_RECTO: 'cni-recto',
  CNI_VERSO: 'cni-verso',
  PHOTO_FACIALE: 'selfie',
};

@Injectable()
export class UploadDocumentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly kycStockage: KycStockageService,
  ) {}

  /**
   * Génère une URL signée pour uploader un document KYC.
   */
  async demanderSignature(
    utilisateurId: string,
    dto: DemanderSignatureDocumentKycDto,
  ) {
    const { typeMime, typeDocument, taille } = dto;

    if (!TYPES_MIME_KYC_AUTORISES.includes(typeMime)) {
      throw new BadRequestException(
        `Type de fichier non autorisé. Formats acceptés : ${TYPES_MIME_KYC_AUTORISES.join(', ')}`,
      );
    }
    if(taille < 1 || taille > MAX_TAILLE_DOCUMENT_KYC) {
      throw new BadRequestException(
        `Taille de fichier non autorisée. Taille maximale : 10 Mo`,
      );
    }

    const dossier = await this.getDossierActif(utilisateurId);

    if (!['EN_ATTENTE', 'REJETE'].includes(dossier.statut)) {
      throw new BadRequestException(
        'Le dossier KYC ne peut plus être modifié.',
      );
    }

    const typeUpload = TYPE_DOCUMENT_VERS_UPLOAD[typeDocument];
    const signature = await this.kycStockage.genererSignature(
      utilisateurId,
      typeUpload,
      typeMime,
    );

    return { ...signature, typeDocument };
  }

  /**
   * Confirme l'upload d'un document après que le client a uploadé sur R2.
   */
  async confirmerUpload(
    utilisateurId: string,
    dto: ConfirmerUploadDocumentKycDto
  ) {
    const { cleStockage, typeMime, taille, typeDocument } = dto;

    if (!TYPES_MIME_KYC_AUTORISES.includes(typeMime)) {
      throw new BadRequestException(
        `Type de fichier non autorisé. Formats acceptés : ${TYPES_MIME_KYC_AUTORISES.join(', ')}`,
      );
    }
    if(taille < 1 || taille > MAX_TAILLE_DOCUMENT_KYC) {
      throw new BadRequestException(
        `Taille de fichier non autorisée. Taille maximale : 10 Mo`,
      );
    }
    
    const dossier = await this.getDossierActif(utilisateurId);

    const reel = await this.kycStockage.verifierUpload(cleStockage, typeMime, utilisateurId, TYPE_DOCUMENT_VERS_UPLOAD[typeDocument]);
    
    return this.prisma.$transaction(async (tx) => {
      // Supprimer l'ancien document du même type s'il existe
      await tx.documentKyc.deleteMany({
        where: { dossierKycId: dossier.id, typeDocument },
      });

      // Créer le nouveau document
      return tx.documentKyc.create({
        data: {
          dossierKycId: dossier.id,
          typeDocument,
          cleStockage,
          nomOriginal: `${typeDocument.toLowerCase()}.${typeMime.split('/')[1]}`,
          typeMime,
          taille,
          statut: 'SOUMIS',
        },
        select: {
          id: true,
          typeDocument: true,
          statut: true,
          dateCreation: true,
        },
      });
    });
  }

  private async getDossierActif(utilisateurId: string) {
    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: utilisateurId },
      select: {
        dossiersKyc: {
          orderBy: { dateSoumission: 'desc' },
          take: 1,
          select: { id: true, statut: true },
        },
      },
    });

    if (!vendeur) throw new ForbiddenException('Profil vendeur introuvable.');

    const dossier = vendeur.dossiersKyc[0];
    if (!dossier) throw new NotFoundException('Dossier KYC introuvable.');

    return dossier;
  }
}