import { Transform } from 'class-transformer';
import {
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

import { FORMAT_PSEUDO, normaliserPseudo } from '../pseudo.js';

/**
 * Le téléphone n'est volontairement pas modifiable ici : un changement de
 * numéro passe par POST /auth/telephone/changer puis /auth/telephone/confirmer.
 * La photo passe par POST /users/me/photo/signature puis PUT /users/me/photo.
 */
export class MiseAJourProfilDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(100)
  nom?: string;

  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(100)
  prenom?: string;

  /** @pseudo public, utilisé pour les mentions. Converti en minuscules. */
  @IsOptional()
  @IsString()
  @Transform(({ value }) =>
    typeof value === 'string' ? normaliserPseudo(value) : value,
  )
  @Matches(FORMAT_PSEUDO, {
    message:
      'Le pseudo doit contenir 3 à 30 caractères : lettres, chiffres, « _ » ou « . ».',
  })
  pseudo?: string;
}
