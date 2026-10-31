import { IsNotEmpty, IsNumber, IsString, MaxLength, Max, Min, ValidateIf } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { COMMISSION_MAX } from '../../parametres/parametres.registre.js';

export class ModifierParametreDto {
  @ApiProperty({ type: Number })
  @IsNumber({ allowNaN: false, allowInfinity: false })
  valeur!: number;
}

export class DefinirCommissionVendeurDto {
  @ApiProperty({
    type: Number,
    nullable: true,
    minimum: 0,
    maximum: COMMISSION_MAX,
    description: 'Taux (0,12 = 12 %). null = revenir au taux par défaut de la plateforme.',
  })
  @ValidateIf((_, valeur) => valeur !== null)
  @IsNumber({ maxDecimalPlaces: 4 })
  @Min(0)
  @Max(COMMISSION_MAX)
  taux!: number | null;

  @ApiProperty({ maxLength: 500 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  raison!: string;
}

export class ParametreDto {
  @ApiProperty() cle!: string;
  @ApiProperty() description!: string;
  @ApiProperty({ enum: ['taux', 'entier'], enumName: 'TypeParametre' }) type!: 'taux' | 'entier';
  @ApiProperty({ type: Number }) valeur!: number;
  @ApiProperty({ type: Number }) valeurParDefaut!: number;
  @ApiProperty({ type: Number }) min!: number;
  @ApiProperty({ type: Number }) max!: number;
  @ApiProperty({ description: 'false : la valeur par défaut du registre s’applique.' })
  personnalise!: boolean;
}

export class CommissionVendeurDto {
  @ApiProperty({ format: 'uuid' }) vendeurId!: string;
  @ApiProperty({ type: Number, nullable: true }) commissionPersonnalisee!: number | null;
  @ApiProperty({ type: Number, description: 'Taux qui s’appliquera aux PROCHAINES commandes.' })
  tauxEffectif!: number;
}