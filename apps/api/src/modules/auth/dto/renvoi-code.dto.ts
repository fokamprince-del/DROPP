import { IsNotEmpty, IsString } from 'class-validator';

export class RenvoiCodeDto {
  @IsString()
  @IsNotEmpty()
  verificationToken!: string;
}