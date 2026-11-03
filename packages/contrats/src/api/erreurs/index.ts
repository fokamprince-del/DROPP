import { KYC_ERRORS } from './kyc.js';
import { UPLOAD_ERRORS } from './upload.js';

export {KYC_ERRORS, UPLOAD_ERRORS}; ;

const ERREURS = {
  ...KYC_ERRORS,
  ...UPLOAD_ERRORS,
} as const;

export type ERREUR_CODES =( typeof ERREURS)[keyof typeof ERREURS];