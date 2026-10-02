import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export enum DecisionKyc {
  VALIDE = 'VALIDE',
  REJETE = 'REJETE',
}

export class DecisionAdminDto {
  @IsEnum(DecisionKyc)
  decision!: DecisionKyc;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  motifRejet?: string;
}