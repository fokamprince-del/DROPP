import {
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

import {
  DIMENSION_MAX_PX,
  DUREE_MAX_S,
  TAILLE_MAX_MEDIA_OCTETS,
  TYPES_MIME_MEDIA,
} from '../../../infrastructure/stockage/media.js';

export class ConfirmerStoryDto {
  /** Clé renvoyée par la demande de signature. */
  @IsString()
  @IsNotEmpty()
  @MaxLength(512)
  cleStockage!: string;

  @IsIn(TYPES_MIME_MEDIA)
  typeMime!: string;

  @IsInt()
  @Min(1)
  @Max(TAILLE_MAX_MEDIA_OCTETS)
  taille!: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(DIMENSION_MAX_PX)
  largeur?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(DIMENSION_MAX_PX)
  hauteur?: number;

  /** Durée en secondes (vidéos). */
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(DUREE_MAX_S)
  duree?: number;
}
