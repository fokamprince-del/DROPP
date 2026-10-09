import { Transform, Type } from 'class-transformer';
import {
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

import { EstAttributsVariante } from './attributs-variante.validator.js';

export class CreerVarianteDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  @Transform(({ value }: { value: string }) => value?.trim())
  sku!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  @Transform(({ value }: { value: string }) => value?.trim())
  nom!: string;

  /**
   * Attributs libres : { "taille": "XL", "couleur": "rouge" }
   * Validé comme objet JSON simple.
   */
  @IsObject()
  @EstAttributsVariante()
  attributs!: Record<string, string>;

  /** Si absent, le prix de la variante est celui du produit (prixBase). */
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  prix?: number;

  @IsInt()
  @Min(0)
  @Type(() => Number)
  stockDisponible!: number;
}
