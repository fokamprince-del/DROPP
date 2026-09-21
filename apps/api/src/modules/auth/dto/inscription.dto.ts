import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsNotEmpty,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Role } from '../types/user-authentified.type.js';

export class InscriptionDto {
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(80)
  @Matches(/^[\p{L}\p{M}][\p{L}\p{M}' -]*$/u, {
    message: 'Le nom contient des caractères invalides.',
  })
  nom!: string;

  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(80)
  @Matches(/^[\p{L}\p{M}][\p{L}\p{M}' -]*$/u, {
    message: 'Le prénom contient des caractères invalides.',
  })
  prenom!: string;

  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail()
  @MaxLength(254)
  email!: string;

  @Transform(({ value }) =>
    typeof value === 'string'
      ? value.replace(/[\s().-]/g, '')
      : value,
  )
  @IsString()
  @Matches(/^\+237[26]\d{8}$/, {
    message: 'Le numéro de téléphone doit être au format +237XXXXXXXXX.',
  })
  telephone!: string;

  @IsString()
  @IsNotEmpty()
  role!: Role;

  @IsString()
  @MinLength(12)
  @MaxLength(128)
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).+$/,
    {
      message:
        'Le mot de passe doit contenir une minuscule, une majuscule, un chiffre et un caractère spécial.',
    },
  )
  motDePasse!: string;
}