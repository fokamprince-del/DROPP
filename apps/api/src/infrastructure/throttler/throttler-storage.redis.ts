import { Logger } from '@nestjs/common';
import type { ThrottlerStorage } from '@nestjs/throttler';
import type { Redis } from 'ioredis';

/** Fenêtre fixe + blocage, en un seul aller-retour atomique. */
const SCRIPT = `
local hits = redis.call('INCR', KEYS[1])
if hits == 1 then redis.call('PEXPIRE', KEYS[1], ARGV[1]) end
local ttl = redis.call('PTTL', KEYS[1])
local bloque = redis.call('PTTL', KEYS[2])
if bloque <= 0 and hits > tonumber(ARGV[2]) then
  redis.call('SET', KEYS[2], '1', 'PX', ARGV[3])
  bloque = tonumber(ARGV[3])
end
return { hits, ttl, bloque }
`;

/**
 * Stockage du rate-limit dans Redis : les compteurs sont partagés entre
 * toutes les instances de l'API (le stockage mémoire par défaut ne l'est pas).
 * Redis indisponible : la requête passe (le service reste disponible).
 */
export class ThrottlerStorageRedis implements ThrottlerStorage {
  private readonly logger = new Logger(ThrottlerStorageRedis.name);

  constructor(private readonly redis: Redis) {}

  async increment(
    key: string,
    ttl: number,
    limit: number,
    blockDuration: number,
    throttlerName: string,
  ) {
    const base = `dropp:throttle:${throttlerName}:${key}`;
    try {
      const [hits, ttlMs, blocageMs] = (await this.redis.eval(
        SCRIPT,
        2,
        `${base}:hits`,
        `${base}:bloque`,
        String(ttl),
        String(limit),
        String(blockDuration > 0 ? blockDuration : ttl),
      )) as [number, number, number];
      const estBloque = blocageMs > 0;
      return {
        totalHits: hits,
        timeToExpire: Math.max(Math.ceil(ttlMs / 1000), 0),
        isBlocked: estBloque,
        timeToBlockExpire: estBloque ? Math.ceil(blocageMs / 1000) : 0,
      };
    } catch (erreur) {
      this.logger.warn(`Rate-limit indisponible : ${String(erreur)}`);
      return { totalHits: 0, timeToExpire: 0, isBlocked: false, timeToBlockExpire: 0 };
    }
  }
}
