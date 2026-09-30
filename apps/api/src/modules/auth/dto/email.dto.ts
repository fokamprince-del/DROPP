import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

const normaliserEmail = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim().toLowerCase() : value;

export class ChangerEmailDto {
  @IsEmail()
  @MaxLength(254)
  @Transform(normaliserEmail)
  email!: string;

  /** Obligatoire si le compte a un mot de passe. */
  @IsOptional()
  @IsString()
  @MaxLength(128)
  motDePasse?: string;
}

export class VerifierEmailDto {
  @IsString()
  @Matches(/^\d{6}$/, { message: 'Le code doit contenir 6 chiffres.' })
  code!: string;

  /** À préciser lors d'un changement d'adresse (sinon : adresse actuelle). */
  @IsOptional()
  @IsEmail()
  @MaxLength(254)
  @Transform(normaliserEmail)
  email?: string;
}

export class ChangerMotDePasseDto {
  @IsString()
  @MaxLength(128)
  ancienMotDePasse!: string;

  @IsString()
  @MaxLength(128)
  nouveauMotDePasse!: string;
}
