import { Transform } from 'class-transformer';
import {
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export class ModifierProduitDto {
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  @Transform(({ value }: { value: string }) => value?.trim())
  nom?: string;

  @IsOptional()
  @IsString()
  @MinLength(10)
  @MaxLength(5000)
  @Transform(({ value }: { value: string }) => value?.trim())
  description?: string;

  @IsOptional()
  @IsUUID()
  categorieId?: string;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  prixBase?: number;
}