import {
  IsNotEmpty,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class ReinitialisationMotDePasseDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{6}$/, {
    message: 'Le code de vérification doit contenir 6 chiffres.',
  })
  code!: string;

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
  nouveauMotDePasse!: string;
}