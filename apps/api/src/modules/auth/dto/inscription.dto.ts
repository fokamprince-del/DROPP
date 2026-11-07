import { Sexe } from '@dropp/database';
import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class InscriptionDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  @Transform(({ value }: { value: string }) => value?.trim())
  prenom!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  @Transform(({ value }: { value: string }) => value?.trim())
  nom!: string;

  @IsString()
  @IsIn(Object.values(Sexe), {
    message: `Le sexe doit être l'une des valeurs suivantes : ${Object.values(Sexe).join(
      ', ',
    )}.`,
  })
  sexe!: Sexe;

  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  telephone!: string;

  @IsOptional()
  @IsEmail()
  @MaxLength(254)
  @Transform(({ value }: { value: string }) => value?.trim().toLowerCase())
  email?: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  motDePasse!: string;
}
