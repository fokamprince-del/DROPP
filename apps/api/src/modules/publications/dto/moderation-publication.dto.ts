import { IsIn } from 'class-validator';

/** PUBLIEE : remise en ligne · REJETEE : retirée du public. */
export class ModerationPublicationDto {
  @IsIn(['PUBLIEE', 'REJETEE'])
  statut!: 'PUBLIEE' | 'REJETEE';
}
