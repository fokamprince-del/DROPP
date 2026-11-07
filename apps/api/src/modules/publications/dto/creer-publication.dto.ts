import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

import {
  TypePublication,
  VisibiliteContenu,
} from '@dropp/database';

export class CreerPublicationDto {
  @IsEnum(TypePublication)
  type!: TypePublication;

  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MaxLength(5000)
  contenu?: string;

  @IsOptional()
  @IsEnum(VisibiliteContenu)
  visibilite?: VisibiliteContenu;

  /** Produits de la boutique présentés dans la publication (5 max, dans l'ordre). */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @ArrayUnique()
  @IsUUID('all', { each: true })
  produitIds?: string[];
}
