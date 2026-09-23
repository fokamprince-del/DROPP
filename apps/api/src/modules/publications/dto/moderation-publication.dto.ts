import { IsEnum } from 'class-validator';

import { StatutPublication } from '../../../generated/prisma/client.js';

export class ModerationPublicationDto {
  @IsEnum(StatutPublication)
  statut!: StatutPublication;
}