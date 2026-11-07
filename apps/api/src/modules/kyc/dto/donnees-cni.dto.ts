import { Transform, Type } from 'class-transformer';
import {
  IsDate,
  IsNotEmpty,
  IsString,
  Matches,
  MaxDate,
  MaxLength,
} from 'class-validator';

const nettoyer = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value;

export class DonneesCniDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  @Transform(nettoyer)
  nomLegal!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  @Transform(nettoyer)
  prenomLegal!: string;

  /** Lettres et chiffres uniquement (espaces et tirets retirés). */
  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.replace(/[\s-]/g, '').toUpperCase() : value,
  )
  @Matches(/^[A-Z0-9]{6,20}$/, { message: 'Numéro de CNI invalide.' })
  numeroCni!: string;

  @Type(() => Date)
  @IsDate()
  @MaxDate(() => new Date(), { message: 'Date de naissance invalide.' })
  dateNaissance!: Date;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  @Transform(nettoyer)
  lieuNaissance!: string;

  @Type(() => Date)
  @IsDate()
  @MaxDate(() => new Date(), { message: 'Date d’établissement invalide.' })
  dateEtablissement!: Date;

  @Type(() => Date)
  @IsDate()
  dateExpiration!: Date;
}
