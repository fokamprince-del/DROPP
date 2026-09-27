import { SetMetadata } from '@nestjs/common';

export const CLE_TELEPHONE_VERIFIE = 'telephone_verifie_requis';

/**
 * Exige que le téléphone de l'utilisateur soit vérifié.
 * À combiner avec @UseGuards(TelephoneVerifieGuard) sur la route ou le contrôleur,
 * ou enregistré globalement dans AppModule après JwtAuthGuard.
 *
 * @example
 * @RequiertTelephoneVerifie()
 * @Post('commande')
 * async passerCommande() { ... }
 */
export const RequiertTelephoneVerifie = () =>
  SetMetadata(CLE_TELEPHONE_VERIFIE, true);
