import { applyDecorators, SetMetadata, UseGuards } from '@nestjs/common';
import type { StatutVendeur } from '@dropp/database';

import { RoleAdminGuard } from '../guards/admin.guard.js';
import { ProfilClientGuard } from '../guards/client.guard.js';
import { ProfilVendeurGuard } from '../guards/vendeur.guard.js';
import type { RoleAdmin } from '../roles.js';
import { CLE_PROFIL_CLIENT } from './profil-client.decorator.js';
import { CLE_PROFIL_VENDEUR } from './profil-vendeur.decorator.js';
import { RequiertTelephoneVerifie } from './require-telephone-verifie.decorator.js';
import { CLE_ROLES_ADMIN } from './role-admin.decorator.js';

export const Client = () =>
  applyDecorators(
    RequiertTelephoneVerifie(),
    SetMetadata(CLE_PROFIL_CLIENT, true),
    UseGuards(ProfilClientGuard),
  );

/**
 * Profil vendeur requis. Par défaut : vendeur ACTIF (KYC validé).
 * Le parcours KYC accepte aussi un vendeur EN_ATTENTE_VALIDATION.
 */
export const Vendeur = (
  ...statuts: [StatutVendeur, ...StatutVendeur[]] | []
) =>
  applyDecorators(
    RequiertTelephoneVerifie(),
    SetMetadata(CLE_PROFIL_VENDEUR, statuts.length ? statuts : ['ACTIF']),
    UseGuards(ProfilVendeurGuard),
  );

/** Au moins un rôle est obligatoire : le garde refuse une liste vide. */
export const Admin = (...roles: [RoleAdmin, ...RoleAdmin[]]) =>
  applyDecorators(
    SetMetadata(CLE_ROLES_ADMIN, roles),
    UseGuards(RoleAdminGuard),
  );
