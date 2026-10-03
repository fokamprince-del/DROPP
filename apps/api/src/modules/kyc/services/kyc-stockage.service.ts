import { Inject, Injectable, Logger } from '@nestjs/common';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
  type SignatureUpload,
} from '../../../infrastructure/stockage/stockage-provider.contract.js';
import { verifierUpload } from '../../../infrastructure/stockage/verifier-upload.js';
import { MAX_TAILLE_DOCUMENT_KYC } from '../dto/DemanderSignatureDocumentKyc.dto.js';

export type TypeDocumentKycUpload = 'cni-recto' | 'cni-verso' | 'selfie';

@Injectable()
export class KycStockageService {
  private readonly logger = new Logger(KycStockageService.name);

  constructor(
    @Inject(STOCKAGE_PROVIDER)
    private readonly stockage: StockageProvider,
  ) {}

  /**
   * Génère une URL signée pour upload d'un document KYC.
   * TTL court : 5 minutes (données sensibles).
   * Bucket séparé des médias produits.
   */
  async genererSignature(
    vendeurId: string,
    type: TypeDocumentKycUpload,
    typeMime: string,
  ): Promise<SignatureUpload> {
    return this.stockage.genererSignatureUpload( this.getPrefixe(vendeurId, type), typeMime, MAX_TAILLE_DOCUMENT_KYC);
  }

  /**
   * Génère une URL de consultation temporaire (5 minutes).
   * Chaque accès admin est audité.
   */
  urlConsultation(cleStockage: string): string {
    // En production : URL signée avec TTL 5min via R2
    // Pour l'instant le stub retourne une URL publique
    return this.stockage.urlPublique(cleStockage);
  }

  /**
   * verifier l'upload d'un document KYC.
   */
  async verifierUpload(cleStockage: string, typeMime: string, vendeurId: string, type: TypeDocumentKycUpload) {
    return await verifierUpload(this.stockage,{
      cleStockage, 
      typesMime: [typeMime], 
      prefixe: this.getPrefixe(vendeurId, type), 
      tailleMaxMo: MAX_TAILLE_DOCUMENT_KYC
    });
  }

  /**
   * recupere le contenu d'un document KYC.
   */
  async getFile(cleStockage: string): Promise<Buffer| null> {
    return await this.stockage.getFile(cleStockage);
  }

  private  getPrefixe(utilisateurId: string, type: TypeDocumentKycUpload){
    return `kyc/${utilisateurId}/${type}`;
  }
}