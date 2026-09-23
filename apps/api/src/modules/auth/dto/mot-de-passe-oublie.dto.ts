import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class MotDePasseOublieDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(254)
  identifiant!: string;
}
