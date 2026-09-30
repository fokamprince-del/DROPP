import { Transform } from 'class-transformer';
import {
  IsDate,
  IsEnum,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

import { VisibiliteContenu } from '../../../generated/prisma/client.js';

export class CreerStoryDto {
  @IsString()
  @IsNotEmpty()
  @IsIn([
    'image/jpeg',
    'image/png',
    'image/webp',
    'video/mp4',
    'video/quicktime',
  ])
  typeMime!: string;

  @IsInt()
  @Min(1)
  @Max(500 * 1024 * 1024)
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
