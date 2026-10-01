import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

import { PlateformeAppareil } from '@dropp/database';

export class EnregistrerAppareilDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  tokenFcm!: string;

  @IsEnum(PlateformeAppareil)
  plateforme!: PlateformeAppareil;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  modele?: string;
}

export class RetirerAppareilDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  tokenFcm!: string;
}
