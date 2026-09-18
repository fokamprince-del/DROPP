import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class VerificationOtpDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{6}$/, {
    message: 'Le code de vérification doit contenir 6 chiffres.',
  })
  code!: string;
}