import { SetMetadata } from '@nestjs/common';

export const CLE_PROFIL_CLIENT = 'profil_client_requis';

/**
 * Exige que l'utilisateur ait un profil Client actif.
 * Utilisez sur toutes les routes panier, commande, avis, favoris.
 *
 * @example
 * @RequiertProfilClient()
 * @Post('panier')
 */
export const RequiertProfilClient = () => SetMetadata(CLE_PROFIL_CLIENT, true);
