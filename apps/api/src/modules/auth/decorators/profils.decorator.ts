import { applyDecorators, SetMetadata, UseGuards } from '@nestjs/common';
import { RoleAdminGuard } from '../guards/admin.guard.js';
import { ProfilClientGuard } from '../guards/client.guard.js';
import { ProfilVendeurGuard } from '../guards/vendeur.guard.js';
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

export const Vendeur = () =>
  applyDecorators(
    RequiertTelephoneVerifie(),
    SetMetadata(CLE_PROFIL_VENDEUR, true),
    UseGuards(ProfilVendeurGuard),
  );

export const Admin = (...roles: string[]) =>
  applyDecorators(
    SetMetadata(CLE_ROLES_ADMIN, roles),
    UseGuards(RoleAdminGuard),
  );
