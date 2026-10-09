import { TypeDocumentKyc } from '@dropp/database';
import { IsIn, IsInt, IsNotEmpty, IsString, Max, MaxLength, Min } from 'class-validator';

import {
  MAX_TAILLE_DOCUMENT_KYC,
  TYPES_MIME_KYC_AUTORISES,
} from './DemanderSignatureDocumentKyc.dto.js';

export class ConfirmerUploadDocumentKycDto {
  /** Clé renvoyée par /kyc/documents/signature. */
  @IsString()
  @IsNotEmpty()
  @MaxLength(512)
  cleStockage!: string;

  @IsIn(TYPES_MIME_KYC_AUTORISES)
  typeMime!: string;

  @IsInt()
  @Min(1)
  @Max(MAX_TAILLE_DOCUMENT_KYC)
  taille!: number;

  @IsIn(Object.values(TypeDocumentKyc))
  typeDocument!: TypeDocumentKyc;
}
