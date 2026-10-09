import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import type { Redis } from 'ioredis';

import { REDIS_CLIENT } from '../../../infrastructure/redis/redis.provider.js';

const MAX_ECHECS = 10;
const FENETRE_S = 15 * 60;

/**
 * Verrouillage par identifiant (en plus du rate-limit par IP) : bloque le
 * brute-force d'un même compte réparti sur de nombreuses adresses IP.
 * Appliqué aussi aux identifiants inconnus, pour ne rien révéler.
 */
@Injectable()
export class VerrouillageService {
  constructor(@Inject(REDIS_CLIENT) private readonly redis: Redis) {}

  async verifier(identifiant: string): Promise<void> {
    const cle = this.cle(identifiant);
    const echecs = Number((await this.redis.get(cle)) ?? 0);
    if (echecs >= MAX_ECHECS) {
      const restant = Math.max(await this.redis.ttl(cle), 60);
      throw new HttpException(
        `Trop de tentatives sur ce compte. Réessayez dans ${Math.ceil(restant / 60)} minute(s) ou utilisez « Mot de passe oublié ».`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  /** Retourne vrai quand cet échec déclenche le verrouillage. */
  async echec(identifiant: string): Promise<boolean> {
    const cle = this.cle(identifiant);
    const [[, echecs]] = (await this.redis
      .pipeline()
      .incr(cle)
      .expire(cle, FENETRE_S, 'NX')
      .exec()) as [[Error | null, number], [Error | null, number]];
    return echecs === MAX_ECHECS;
  }

  async reussite(identifiant: string): Promise<void> {
    await this.redis.del(this.cle(identifiant));
  }

  private cle(identifiant: string) {
    return `dropp:echecs-connexion:${identifiant}`;
  }
}
