import {
  cleRevocationSession,
  cleRevocationUtilisateur,
  jetonRevoque,
} from '../../src/infrastructure/revocation/revocation.js';
import { RedisMemoire } from '../utils/redis-memoire.js';

describe('jetonRevoque', () => {
  const maintenant = Math.floor(Date.now() / 1000);

  it('accepte un jeton sans révocation', async () => {
    const redis = new RedisMemoire();
    await expect(
      jetonRevoque(redis.commeRedis(), { sub: 'u', sid: 's', iat: maintenant }),
    ).resolves.toBe(false);
  });

  it('refuse un jeton dont la session a été fermée', async () => {
    const redis = new RedisMemoire();
    await redis.set(cleRevocationSession('s'), '1');
    await expect(
      jetonRevoque(redis.commeRedis(), { sub: 'u', sid: 's', iat: maintenant }),
    ).resolves.toBe(true);
  });

  it('refuse les jetons émis avant une révocation globale, pas ceux émis après', async () => {
    const redis = new RedisMemoire();
    await redis.set(cleRevocationUtilisateur('u'), String(maintenant));
    await expect(
      jetonRevoque(redis.commeRedis(), { sub: 'u', iat: maintenant - 10 }),
    ).resolves.toBe(true);
    await expect(
      jetonRevoque(redis.commeRedis(), { sub: 'u', iat: maintenant }),
    ).resolves.toBe(false);
  });

  it('laisse passer si Redis est indisponible', async () => {
    const enPanne = {
      mget: async () => {
        throw new Error('ECONNREFUSED');
      },
    };
    await expect(
      jetonRevoque(enPanne as never, { sub: 'u', iat: maintenant }),
    ).resolves.toBe(false);
  });
});
