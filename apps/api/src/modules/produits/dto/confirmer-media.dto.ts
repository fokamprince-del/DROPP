import {
  IsIn,
  IsInt,
  IsNotEmpty,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

const TYPES_MIME_AUTORISES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'video/mp4',
  'video/quicktime',
] as const;

export class ConfirmerMediaDto {
  /** Clé retournée par la signature d'upload. */
  @IsString()
  @IsNotEmpty()
  @MaxLength(512)
  cleStockage!: string;

  @IsString()
  @IsIn(TYPES_MIME_AUTORISES)
  typeMime!: string;

  @IsInt()
  @Min(1)
  @Max(500 * 1024 * 1024)
  taille!: number;

  @IsUUID()
  produitId!: string;
}
