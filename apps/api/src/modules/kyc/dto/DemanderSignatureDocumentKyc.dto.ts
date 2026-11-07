import { TypeDocumentKyc } from '@dropp/database';
import { IsIn, IsInt, Max, Min } from 'class-validator';

export const TYPES_MIME_KYC_AUTORISES = ['image/jpeg', 'image/png', 'image/webp'];

export const MAX_TAILLE_DOCUMENT_KYC_MO = 10;
export const MAX_TAILLE_DOCUMENT_KYC = MAX_TAILLE_DOCUMENT_KYC_MO * 1024 * 1024;

export class DemanderSignatureDocumentKycDto {
  @IsIn(TYPES_MIME_KYC_AUTORISES)
  typeMime!: string;

  /** Taille en octets (10 Mo max). */
  @IsInt()
  @Min(1)
  @Max(MAX_TAILLE_DOCUMENT_KYC)
  taille!: number;

  @IsIn(Object.values(TypeDocumentKyc))
  typeDocument!: TypeDocumentKyc;
}
