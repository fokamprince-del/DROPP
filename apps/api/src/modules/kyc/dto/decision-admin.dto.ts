import { Transform } from 'class-transformer';
import { IsEnum, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export enum DecisionKyc {
  VALIDE = 'VALIDE',
  REJETE = 'REJETE',
}

export class DecisionAdminDto {
  @IsEnum(DecisionKyc)
  decision!: DecisionKyc;

  /** Obligatoire en cas de rejet : affiché au vendeur. */
  @IsOptional()
  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsNotEmpty()
  @MaxLength(500)
  motifRejet?: string;
}
