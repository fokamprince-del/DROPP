import { Injectable, Logger } from '@nestjs/common';

import type { TypeDocumentKyc } from '@dropp/database';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { ConfirmerUploadDocumentKycDto } from '../dto/confirmer-upload-document-kyc.dto.js';
import type { DemanderSignatureDocumentKycDto } from '../dto/DemanderSignatureDocumentKyc.dto.js';
import { DossierKycService } from '../services/dossier-kyc.service.js';
import {
  KycStockageService,
  type TypeDocumentKycUpload,
} from '../services/kyc-stockage.service.js';

const TYPE_DOCUMENT_VERS_UPLOAD: Record<TypeDocumentKyc, TypeDocumentKycUpload> = {
  CNI_RECTO: 'cni-recto',
  CNI_VERSO: 'cni-verso',
  PHOTO_FACIALE: 'selfie',
};

@Injectable()
export class UploadDocumentService {
  private readonly logger = new Logger(UploadDocumentService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly kycStockage: KycStockageService,
    private readonly dossiers: DossierKycService,
  ) {}

  /** 1. URL signée pour uploader une pièce (PUT direct vers le stockage privé). */
  async demanderSignature(
    utilisateurId: string,
    dto: DemanderSignatureDocumentKycDto,
  ) {
    await this.dossiers.modifiable(utilisateurId);
    const signature = await this.kycStockage.genererSignature(
      utilisateurId,
      TYPE_DOCUMENT_VERS_UPLOAD[dto.typeDocument],
      dto.typeMime,
    );
    return { ...signature, typeDocument: dto.typeDocument };
  }

  /** 2. Confirmation après l'upload : remplace la pièce précédente du même type. */
  async confirmerUpload(utilisateurId: string, dto: ConfirmerUploadDocumentKycDto) {
    const { cleStockage, typeMime, typeDocument } = dto;
    const dossier = await this.dossiers.modifiable(utilisateurId);

    const reel = await this.kycStockage.verifierUpload(
      cleStockage,
      utilisateurId,
      TYPE_DOCUMENT_VERS_UPLOAD[typeDocument],
    );

    const anciens = await this.prisma.documentKyc.findMany({
      where: { dossierKycId: dossier.id, typeDocument },
      select: { cleStockage: true },
    });

    const document = await this.prisma.$transaction(async (tx) => {
      await tx.documentKyc.deleteMany({
        where: { dossierKycId: dossier.id, typeDocument },
      });
      return tx.documentKyc.create({
        data: {
          dossierKycId: dossier.id,
          typeDocument,
          cleStockage,
          nomOriginal: `${typeDocument.toLowerCase()}.${typeMime.split('/')[1]}`,
          typeMime: reel.typeMime ?? typeMime,
          taille: reel.taille,
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

    // Pièce d'identité remplacée : l'ancien fichier ne doit pas rester stocké.
    for (const ancien of anciens) {
      if (ancien.cleStockage === cleStockage) continue;
      await this.kycStockage
        .supprimer(ancien.cleStockage)
        .catch((e: unknown) => this.logger.warn(`KYC ${ancien.cleStockage} : ${String(e)}`));
    }
    return document;
  }
}
