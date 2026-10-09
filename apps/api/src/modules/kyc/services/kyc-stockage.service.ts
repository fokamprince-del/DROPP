import { Inject, Injectable } from '@nestjs/common';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
  type SignatureUpload,
} from '../../../infrastructure/stockage/stockage-provider.contract.js';
import { verifierUpload } from '../../../infrastructure/stockage/verifier-upload.js';
import {
  MAX_TAILLE_DOCUMENT_KYC_MO,
  TYPES_MIME_KYC_AUTORISES,
} from '../dto/DemanderSignatureDocumentKyc.dto.js';

export type TypeDocumentKycUpload = 'cni-recto' | 'cni-verso' | 'selfie';

/** Lien de consultation d'une pièce d'identité par un administrateur. */
const DUREE_CONSULTATION_S = 5 * 60;

/**
 * Pièces d'identité : préfixe kyc/ → bucket privé, jamais d'URL publique.
 * Lecture uniquement par URL signée de courte durée.
 */
@Injectable()
export class KycStockageService {
  constructor(
    @Inject(STOCKAGE_PROVIDER)
    private readonly stockage: StockageProvider,
  ) {}

  genererSignature(
    vendeurId: string,
    type: TypeDocumentKycUpload,
    typeMime: string,
  ): Promise<SignatureUpload> {
    return this.stockage.genererSignatureUpload(
      this.prefixe(vendeurId, type),
      typeMime,
      MAX_TAILLE_DOCUMENT_KYC_MO,
    );
  }

  /** URL signée (5 min par défaut) : consultation admin, vérification faciale. */
  urlConsultation(cleStockage: string, dureeSecondes = DUREE_CONSULTATION_S) {
    return this.stockage.urlSignee(cleStockage, dureeSecondes);
  }

  verifierUpload(
    cleStockage: string,
    vendeurId: string,
    type: TypeDocumentKycUpload,
  ) {
    return verifierUpload(this.stockage, {
      cleStockage,
      typesMime: TYPES_MIME_KYC_AUTORISES,
      prefixe: this.prefixe(vendeurId, type),
      tailleMaxMo: MAX_TAILLE_DOCUMENT_KYC_MO,
    });
  }

  getFile(cleStockage: string): Promise<Buffer | null> {
    return this.stockage.getFile(cleStockage);
  }

  supprimer(cleStockage: string): Promise<void> {
    return this.stockage.supprimer(cleStockage);
  }

  private prefixe(vendeurId: string, type: TypeDocumentKycUpload) {
    return `kyc/${vendeurId}/${type}`;
  }
}
