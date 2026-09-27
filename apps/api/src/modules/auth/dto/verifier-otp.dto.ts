import { IsNotEmpty, IsString, Length } from 'class-validator';

export class VerifierOtpDto {
  @IsString()
  @IsNotEmpty()
  verificationToken!: string;

  @IsString()
  @Length(6, 6)
  code!: string;
}
