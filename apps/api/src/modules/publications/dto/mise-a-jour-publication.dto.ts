import { Transform } from 'class-transformer';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

import { VisibiliteContenu } from '@dropp/database';

export class MiseAJourPublicationDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MaxLength(5000)
  contenu?: string;

  @IsOptional()
  @IsEnum(VisibiliteContenu)
  visibilite?: VisibiliteContenu;
}
