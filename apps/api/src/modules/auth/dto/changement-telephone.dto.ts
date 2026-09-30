import {
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

export class DemanderChangementTelephoneDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  nouveauTelephone!: string;

  /** Obligatoire si le compte a un mot de passe. */
  @IsOptional()
  @IsString()
  @MaxLength(128)
  motDePasse?: string;
}

export class ConfirmerChangementTelephoneDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  nouveauTelephone!: string;

  @IsString()
  @Matches(/^\d{6}$/, { message: 'Le code doit contenir 6 chiffres.' })
  code!: string;
}

export class SupprimerCompteDto {
  /** Obligatoire si le compte a un mot de passe. */
  @IsOptional()
  @IsString()
  @MaxLength(128)
  motDePasse?: string;
}
