import { Type } from 'class-transformer';
import {
  IsDate,
  IsEnum,
  IsIn,
  IsInt,
  IsNotEmpty,
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

  @Type(() => Date)
  @IsDate()
  dateExpiration!: Date;

  @IsEnum(VisibiliteContenu)
  visibilite: VisibiliteContenu = VisibiliteContenu.PUBLIC;
}
