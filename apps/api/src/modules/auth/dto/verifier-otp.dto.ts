import { IsNotEmpty, IsString, Length } from 'class-validator';

export class VerifierOtpDto {
  /** Téléphone normalisé ou email — même valeur que celle utilisée à l'inscription. */
  @IsString()
  @IsNotEmpty()
  destination!: string;

  @IsString()
  @Length(6, 6)
  code!: string;
}