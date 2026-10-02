export const QUEUE_KYC = 'kyc' as const;

export const JOB_KYC = {
  VERIFIER_VISAGE: 'kyc.verifier-visage',
  EXTRAIRE_OCR: 'kyc.extraire-ocr',
} as const;

export type JobVerifierVisageKyc = {
  dossierKycId: string;
  vendeurId: string;
  cleStockageSelfie: string;
  cleStockageCniRecto: string;
};

export type JobExtraireOcrKyc = {
  dossierKycId: string;
  documentKycId: string;
  cleStockage: string;
};