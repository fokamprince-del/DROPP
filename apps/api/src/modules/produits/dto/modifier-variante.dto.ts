import { Type } from 'class-transformer';
import {
  IsInt,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

import { EstAttributsVariante } from './attributs-variante.validator.js';

export class ModifierVarianteDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  nom?: string;

  @IsOptional()
  @IsObject()
  @EstAttributsVariante()
  attributs?: Record<string, string>;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  prix?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  stockDisponible?: number;
}
