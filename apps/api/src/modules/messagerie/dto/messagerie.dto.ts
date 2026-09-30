import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

/** Taille max en Mo par type accepté en pièce jointe. */
export const TAILLE_MAX_PIECE_JOINTE: Record<string, number> = {
  'image/jpeg': 10,
  'image/png': 10,
  'image/webp': 10,
  'video/mp4': 100,
  'video/quicktime': 100,
};
const TYPES_MIME = Object.keys(TAILLE_MAX_PIECE_JOINTE);

export class OuvrirConversationDto {
  /** Utilisateur à contacter (pour une boutique : son id, identique à celui du vendeur). */
  @IsUUID()
  destinataireId!: string;
}

export class SignaturePieceJointeDto {
  @IsIn(TYPES_MIME)
  typeMime!: string;

  @IsInt()
  @Min(1)
  @Max(100 * 1024 * 1024)
  taille!: number;
}

export class PieceJointeDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(512)
  cleStockage!: string;

  @IsIn(TYPES_MIME)
  typeMime!: string;

  @IsInt()
  @Min(1)
  @Max(100 * 1024 * 1024)
  taille!: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  largeur?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  hauteur?: number;

  /** Durée en secondes (vidéos). */
  @IsOptional()
  @IsInt()
  @Min(1)
  duree?: number;
}

export class EnvoyerMessageDto {
  @IsOptional()
  @IsString()
  @MaxLength(4000)
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  contenu?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @ValidateNested({ each: true })
  @Type(() => PieceJointeDto)
  piecesJointes?: PieceJointeDto[];
}
