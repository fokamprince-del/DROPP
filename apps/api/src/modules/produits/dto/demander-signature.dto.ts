import {
  IsIn,
  IsInt,
  IsNotEmpty,
  IsString,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

const TYPES_MIME_AUTORISES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'video/mp4',
  'video/quicktime',
] as const;

export class DemanderSignatureDto {
  @IsUUID()
  produitId!: string;

  @IsString()
  @IsNotEmpty()
  @IsIn(TYPES_MIME_AUTORISES)
  typeMime!: string;

  /** Taille du fichier en octets (envoyée par l'app avant l'upload). */
  @IsInt()
  @Min(1)
  @Max(500 * 1024 * 1024) // 500 Mo max (vidéos)
  taille!: number;
}
