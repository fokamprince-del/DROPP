import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class ConfirmerMediaPublicationDto {
  @IsString()
  @IsNotEmpty()
  cleStockage!: string;

  @IsString()
  @IsNotEmpty()
  typeMime!: string;

  @IsInt()
  @Min(1)
  @Max(500 * 1024 * 1024)
  taille!: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  largeur?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  hauteur?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  duree?: number;
}
