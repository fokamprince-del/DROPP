import { Transform } from 'class-transformer';
import {
  IsIn,
  IsNotEmpty,
  IsString,
  IsUUID,
  MaxLength,
  ValidateIf,
} from 'class-validator';

export const TYPES_CIBLE = [
  'PUBLICATION',
  'COMMENTAIRE',
  'PRODUIT',
  'BOUTIQUE',
  'MESSAGE',
] as const;
export type TypeCible = (typeof TYPES_CIBLE)[number];

export const MOTIFS = {
  SPAM: 'Spam ou publicité abusive',
  ARNAQUE: 'Arnaque ou fraude',
  CONTREFACON: 'Contrefaçon',
  PRODUIT_INTERDIT: 'Produit interdit ou dangereux',
  CONTENU_INAPPROPRIE: 'Contenu inapproprié ou sexuel',
  HARCELEMENT: 'Harcèlement ou intimidation',
  VIOLENCE_HAINE: 'Violence ou discours haineux',
  FAUSSE_INFORMATION: 'Fausse information / description trompeuse',
  AUTRE: 'Autre',
} as const;
export type Motif = keyof typeof MOTIFS;

export class CreerSignalementDto {
  @IsIn(TYPES_CIBLE)
  typeCible!: TypeCible;

  @IsUUID()
  cibleId!: string;

  @IsIn(Object.keys(MOTIFS))
  motif!: Motif;

  /** Obligatoire pour le motif AUTRE. */
  @ValidateIf((o: CreerSignalementDto) => o.motif === 'AUTRE' || o.description !== undefined)
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  description?: string;
}
