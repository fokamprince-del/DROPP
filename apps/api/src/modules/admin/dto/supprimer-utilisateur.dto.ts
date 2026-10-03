import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class SupprimerUtilisateurDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  raison!: string;
}