import { SetMetadata } from "@nestjs/common";

export const CLE_PROFIL_VENDEUR = 'profil_vendeur_requis';

/**
 * Exige que l'utilisateur ait un profil Vendeur actif (KYC validé).
 * Utilisez sur toutes les routes de gestion de boutique, produits, commandes vendeur.
 *
 * @example
 * @RequiertProfilVendeur()
 * @Post('boutique/produits')
 */
export const RequiertProfilVendeur = () =>
  SetMetadata(CLE_PROFIL_VENDEUR, true);
