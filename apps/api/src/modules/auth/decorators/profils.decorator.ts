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
import { ApiForbiddenResponse } from '@nestjs/swagger';
import { ErreurApiDto } from '../../../infrastructure/http/erreur-api.dto.js';

const refus = (description: string) => ApiForbiddenResponse({ description, type: ErreurApiDto });

export const Client = () =>
  applyDecorators(
    RequiertTelephoneVerifie(),
    SetMetadata(CLE_PROFIL_CLIENT, true),
    UseGuards(ProfilClientGuard),
    refus('Profil client actif requis, ou téléphone non vérifié.'),
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
    refus('Profil vendeur actif requis (KYC validé), ou téléphone non vérifié.'),
  );

/** Au moins un rôle est obligatoire : le garde refuse une liste vide. */
export const Admin = (...roles: [RoleAdmin, ...RoleAdmin[]]) =>
  applyDecorators(
    SetMetadata(CLE_ROLES_ADMIN, roles),
    UseGuards(RoleAdminGuard),
    refus(`Rôle d’administration requis : ${roles.join(' ou ')}.`),
  );
