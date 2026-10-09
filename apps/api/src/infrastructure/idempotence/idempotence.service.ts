import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Redis } from 'ioredis';

import { REDIS_CLIENT } from '../redis/redis.provider.js';

export interface ResultatIdempotent {
  statusCode: number;
  body: unknown;
}

const EN_COURS = 'PENDING';

@Injectable()
export class IdempotenceService {
  private readonly ttl: number;

  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    config: ConfigService,
  ) {
    this.ttl = config.getOrThrow<number>('redis.idempotenceTtl');
  }

  private cle(key: string): string {
    return `dropp:idempotence:${key}`;
  }

  /** Résultat mis en cache, ou null (première requête ou encore en cours). */
  async lire(key: string): Promise<ResultatIdempotent | null> {
    const brut = await this.redis.get(this.cle(key));
    if (!brut || brut === EN_COURS) return null;
    return JSON.parse(brut) as ResultatIdempotent;
  }

  /**
   * Marque une clé « en cours » (SET NX, 30 s max de traitement).
   * Retourne false si la clé existe déjà (requête concurrente ou terminée).
   */
  async marquerEnCours(key: string): Promise<boolean> {
    const resultat = await this.redis.set(this.cle(key), EN_COURS, 'EX', 30, 'NX');
    return resultat === 'OK';
  }

  /** Stocke le résultat final avec le TTL complet. */
  async stocker(key: string, resultat: ResultatIdempotent): Promise<void> {
    await this.redis.set(this.cle(key), JSON.stringify(resultat), 'EX', this.ttl);
  }

  /** Requête en échec : la clé est libérée pour un nouvel essai. */
  async liberer(key: string): Promise<void> {
    await this.redis.del(this.cle(key)).catch(() => 0);
  }
}
