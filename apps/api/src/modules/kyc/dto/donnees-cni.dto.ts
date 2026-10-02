import { Transform, Type } from 'class-transformer';
import {
  IsDate,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class DonneesCniDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  @Transform(({ value }: { value: string }) => value?.trim())
  nomLegal!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  @Transform(({ value }: { value: string }) => value?.trim())
  prenomLegal!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  numeroCni!: string;

  @Type(() => Date)
  @IsDate()
  dateNaissance!: Date;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  lieuNaissance!: string;

  @Type(() => Date)
  @IsDate()
  dateEtablissement!: Date;

  @Type(() => Date)
  @IsDate()
  dateExpiration!: Date;
}