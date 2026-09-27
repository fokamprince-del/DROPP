import { IsEnum } from 'class-validator';

import { StatutPublication } from '@dropp/database';

export class ModerationPublicationDto {
  @IsEnum(StatutPublication)
  statut!: StatutPublication;
}
