import { IsEnum } from 'class-validator';

export enum PlatformePartage {
  WHATSAPP = 'WHATSAPP',
  INSTAGRAM = 'INSTAGRAM',
  COPIER_LIEN = 'COPIER_LIEN',
  INTERNE = 'INTERNE',
}

export class PartagerDto {
  @IsEnum(PlatformePartage)
  plateforme!: PlatformePartage;
}
