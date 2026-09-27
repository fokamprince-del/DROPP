import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Redis } from 'ioredis';

import { REDIS_CLIENT } from '../redis/redis.provider.js';

export interface ResultatIdempotent {
  statusCode: number;
  body: unknown;
}

@Injectable()
export class IdempotenceService {
  private readonly ttl: number;

  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    private readonly config: ConfigService,
  ) {
    this.ttl = config.getOrThrow<number>('redis.idempotenceTtl');
  }

  private cle(key: string): string {
    return `dropp:idempotence:${key}`;
  }

  async lireBrut(key: string): Promise<string | null> {
    return await this.redis.get(this.cle(key));
  }
  /**
   * Vérifie si une clé existe déjà.
   * Retourne le résultat mis en cache ou null si première requête.
   */
  async lire(key: string): Promise<ResultatIdempotent | null> {
    const brut = await this.redis.get(this.cle(key));
    if (!brut || brut === 'PENDING') return null;
    return JSON.parse(brut) as ResultatIdempotent;
  }

  /**
   * Marque une clé comme "en cours" (valeur vide avec TTL court).
   * Retourne false si la clé existe déjà (requête concurrente).
   * Utilise SET NX pour garantir l'atomicité.
   */
  async marquerEnCours(key: string): Promise<boolean> {
    const resultat = await this.redis.set(
      this.cle(key),
      'PENDING',
      'EX',
      30, // 30 secondes max pour traiter la requête
      'NX', // Only if Not exists
    );
    return resultat === 'OK';
  }

  /**
   * Stocke le résultat final avec le TTL complet (24h).
   */
  async stocker(key: string, resultat: ResultatIdempotent): Promise<void> {
    await this.redis.set(
      this.cle(key),
      JSON.stringify(resultat),
      'EX',
      this.ttl,
    );
  }

  /**
   * Vérifie si une requête est encore en cours de traitement.
   */
  estEnCours(brut: string): boolean {
    return brut === 'PENDING';
  }
}
