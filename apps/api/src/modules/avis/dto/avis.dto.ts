import { Transform } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

const nettoyer = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() || undefined : value;

export class CreerAvisDto {
  /** Ligne de commande (article acheté) évaluée. */
  @IsUUID()
  ligneSousCommandeId!: string;

  @IsInt()
  @Min(1)
  @Max(5)
  note!: number;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  @Transform(nettoyer)
  commentaire?: string;
}

export class ModifierAvisDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  note?: number;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  @Transform(nettoyer)
  commentaire?: string;
}
