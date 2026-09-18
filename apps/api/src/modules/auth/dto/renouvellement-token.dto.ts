import { IsNotEmpty, IsString } from 'class-validator';

export class RenouvellementTokenDto {
  @IsString()
  @IsNotEmpty()
  jetonRafraichissement!: string;
}