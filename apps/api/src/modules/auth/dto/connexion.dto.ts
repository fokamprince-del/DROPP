import { Transform } from 'class-transformer';
import {
  IsNotEmpty,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

export class ConnexionDto {
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
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
  @MaxLength(128)
  motDePasse!: string;
}