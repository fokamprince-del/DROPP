import { UnauthorizedException } from '@nestjs/common';
import type { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';

import type { PrismaService } from '../../src/infrastructure/database/prisma.service.js';
import type { RevocationService } from '../../src/infrastructure/revocation/revocation.service.js';
import { JetonService } from '../../src/modules/auth/services/jeton.service.js';

const CONFIG: Record<string, unknown> = {
  'auth.refreshTokenTtlSeconds': 30 * 86400,
  'auth.accessTokenTtlSeconds': 900,
};
const config = { getOrThrow: (c: string) => CONFIG[c] } as ConfigService;
const jwt = new JwtService({ secret: 'secret-de-test-tres-long-pour-hs256-0123456789' });

function contexte(options: { statutCompte?: string; dejaTourne?: boolean; revoque?: boolean }) {
  const revocations: string[] = [];
  const revocation = {
    revoquerUtilisateur: async (id: string) => void revocations.push(id),
    revoquerSessions: async () => undefined,
  } as unknown as RevocationService;

  const session = {
    id: 's1',
    utilisateurId: 'u1',
    familleJeton: 'f1',
    methodeAuth: 'TELEPHONE_MDP',
    adresseIpCreation: null,
    appareilId: null,
    dateRevocation: options.revoque ? new Date() : null,
    dateExpiration: new Date(Date.now() + 86_400_000),
    utilisateur: {
      statutCompte: options.statutCompte ?? 'ACTIF',
      telephoneVerifieLe: new Date(),
    },
  };
  const tx = {
    session: {
      updateMany: async () => ({ count: options.dejaTourne ? 0 : 1 }),
      create: async () => ({ id: 's2' }),
    },
  };
  const prisma = {
    session: {
      findUnique: async () => session,
      updateMany: async () => ({ count: 1 }),
    },
    journalSecurite: { create: async () => ({}) },
    $transaction: async (fn: (t: typeof tx) => unknown) => fn(tx),
  } as unknown as PrismaService;

  return { service: new JetonService(prisma, jwt, config, revocation), revocations };
}

describe('JetonService.rafraichir', () => {
  it('émet de nouveaux jetons portant la nouvelle session', async () => {
    const { service } = contexte({});
    const jetons = await service.rafraichir('ancien');
    expect(jwt.decode(jetons.accessToken)).toMatchObject({ sub: 'u1', sid: 's2' });
  });

  it('jeton déjà tourné par une requête concurrente : famille révoquée', async () => {
    const { service, revocations } = contexte({ dejaTourne: true });
    await expect(service.rafraichir('ancien')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(revocations).toEqual(['u1']);
  });

  it('réutilisation d’un jeton révoqué : famille révoquée', async () => {
    const { service, revocations } = contexte({ revoque: true });
    await expect(service.rafraichir('ancien')).rejects.toThrow('compromise');
    expect(revocations).toEqual(['u1']);
  });

  it('compte suspendu : aucun nouveau jeton', async () => {
    const { service, revocations } = contexte({ statutCompte: 'SUSPENDU_TEMP' });
    await expect(service.rafraichir('ancien')).rejects.toThrow('Compte indisponible');
    expect(revocations).toEqual(['u1']);
  });
});
