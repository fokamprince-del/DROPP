import { Transform } from 'class-transformer';
import {
  IsDate,
  IsEnum,
  IsIn,
  IsInt,
  IsOptional,
  Max,
  Min,
} from 'class-validator';

import { VisibiliteContenu } from '@dropp/database';
import {
  TAILLE_MAX_MEDIA_OCTETS,
  TYPES_MIME_MEDIA,
} from '../../../infrastructure/stockage/media.js';

export class CreerStoryDto {
  @IsIn(TYPES_MIME_MEDIA)
  typeMime!: string;

  @IsInt()
  @Min(1)
  @Max(TAILLE_MAX_MEDIA_OCTETS)
  taille!: number;

  /** Par défaut : 24 h. Au plus 24 h après la création. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    value === undefined || value === null || value === ''
      ? undefined
      : new Date(value as string),
  )
  @IsDate()
  dateExpiration?: Date;

  @IsEnum(VisibiliteContenu)
  visibilite: VisibiliteContenu = VisibiliteContenu.PUBLIC;
}
