import { IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';

export class ConnexionDto {
  /** Email ou numéro de téléphone. Le serveur détecte via la présence de @. */
  @IsString()
  @IsNotEmpty()
  @MaxLength(254)
  identifiant!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  motDePasse!: string;
}