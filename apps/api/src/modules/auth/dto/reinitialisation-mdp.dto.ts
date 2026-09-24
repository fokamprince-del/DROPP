import {
  IsNotEmpty,
  IsString,
  Length,
  MaxLength,
  MinLength,
} from 'class-validator';

export class ReinitialisationMdpDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(254)
  destination!: string;

  @IsString()
  @Length(6, 6)
  code!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  nouveauMotDePasse!: string;
}
