import { IsIn, IsInt, IsNotEmpty, IsString, Max, MaxLength, Min } from 'class-validator';

/** Photos de profil, logos, bannières : images uniquement, 5 Mo max. */
export const TYPES_MIME_IMAGE = ['image/jpeg', 'image/png', 'image/webp'] as const;
export const TAILLE_MAX_IMAGE_MO = 5;

export class SignatureImageDto {
  @IsIn(TYPES_MIME_IMAGE)
  typeMime!: string;

  @IsInt()
  @Min(1)
  @Max(TAILLE_MAX_IMAGE_MO * 1024 * 1024)
  taille!: number;
}

export class ConfirmerImageDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(512)
  cleStockage!: string;
}
