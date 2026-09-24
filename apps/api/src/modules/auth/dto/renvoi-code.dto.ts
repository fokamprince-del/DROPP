import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class RenvoiCodeDto {
  /** Téléphone ou email — même valeur que celle utilisée à l'inscription. */
  @IsString()
  @IsNotEmpty()
  @MaxLength(254)
  destination!: string;
}
