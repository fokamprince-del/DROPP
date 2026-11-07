import { Equals, IsBoolean } from 'class-validator';

export class SoumettreDossierKycDto {
  /**
   * Le vendeur accepte le traitement de ses pièces d'identité, y compris la
   * comparaison faciale réalisée par un prestataire externe (Face++).
   */
  @IsBoolean()
  @Equals(true, { message: 'Vous devez accepter le traitement de vos pièces d’identité.' })
  consentement!: boolean;
}
