import { ForbiddenException, type ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

import type { PrismaService } from '../../src/infrastructure/database/prisma.service.js';
import { CLE_PROFIL_VENDEUR } from '../../src/modules/auth/decorators/profil-vendeur.decorator.js';
import { CLE_ROLES_ADMIN } from '../../src/modules/auth/decorators/role-admin.decorator.js';
import { RoleAdminGuard } from '../../src/modules/auth/guards/admin.guard.js';
import { ProfilVendeurGuard } from '../../src/modules/auth/guards/vendeur.guard.js';

function contexte(metadonnees: Record<string, unknown>, user?: { id: string }) {
  const handler = () => undefined;
  for (const [cle, valeur] of Object.entries(metadonnees)) {
    Reflect.defineMetadata(cle, valeur, handler);
  }
  return {
    getHandler: () => handler,
    getClass: () => class {},
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
  } as unknown as ExecutionContext;
}

describe('RoleAdminGuard', () => {
  const prisma = (roles: string[]) =>
    ({
      utilisateurRole: {
        findFirst: async ({ where }: { where: { role: { nom: { in: string[] } } } }) =>
          roles.some((r) => where.role.nom.in.includes(r)) ? { roleId: 'r' } : null,
      },
    }) as unknown as PrismaService;

  it('refuse par défaut quand aucun rôle n’est déclaré', async () => {
    const garde = new RoleAdminGuard(new Reflector(), prisma(['SUPER_ADMIN']));
    await expect(garde.canActivate(contexte({}, { id: 'a' }))).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    await expect(
      garde.canActivate(contexte({ [CLE_ROLES_ADMIN]: [] }, { id: 'a' })),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('refuse un utilisateur sans le rôle requis', async () => {
    const garde = new RoleAdminGuard(new Reflector(), prisma([]));
    await expect(
      garde.canActivate(contexte({ [CLE_ROLES_ADMIN]: ['MODERATEUR'] }, { id: 'a' })),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('accepte un utilisateur ayant un des rôles', async () => {
    const garde = new RoleAdminGuard(new Reflector(), prisma(['MODERATEUR']));
    await expect(
      garde.canActivate(
        contexte({ [CLE_ROLES_ADMIN]: ['SUPER_ADMIN', 'MODERATEUR'] }, { id: 'a' }),
      ),
    ).resolves.toBe(true);
  });
});

describe('ProfilVendeurGuard', () => {
  const prisma = (statutVendeur: string | null) =>
    ({
      vendeur: {
        findUnique: async () => (statutVendeur ? { statutVendeur } : null),
      },
    }) as unknown as PrismaService;

  it('exige un vendeur ACTIF par défaut', async () => {
    const garde = new ProfilVendeurGuard(new Reflector(), prisma('EN_ATTENTE_VALIDATION'));
    await expect(
      garde.canActivate(contexte({ [CLE_PROFIL_VENDEUR]: ['ACTIF'] }, { id: 'v' })),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('ouvre le parcours KYC aux vendeurs en attente de validation', async () => {
    const garde = new ProfilVendeurGuard(new Reflector(), prisma('EN_ATTENTE_VALIDATION'));
    await expect(
      garde.canActivate(
        contexte({ [CLE_PROFIL_VENDEUR]: ['EN_ATTENTE_VALIDATION'] }, { id: 'v' }),
      ),
    ).resolves.toBe(true);
  });

  it('refuse sans profil vendeur', async () => {
    const garde = new ProfilVendeurGuard(new Reflector(), prisma(null));
    await expect(
      garde.canActivate(contexte({ [CLE_PROFIL_VENDEUR]: ['ACTIF'] }, { id: 'v' })),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
