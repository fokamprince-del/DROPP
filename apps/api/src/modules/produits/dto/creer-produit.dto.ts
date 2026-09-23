import { Transform } from 'class-transformer';
import {
  IsNotEmpty,
  IsNumber,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export class CreerProduitDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(200)
  @Transform(({ value }: { value: string }) => value?.trim())
  nom!: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(10)
  @MaxLength(5000)
  @Transform(({ value }: { value: string }) => value?.trim())
  description!: string;

  @IsUUID()
  categorieId!: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  prixBase!: number;
}