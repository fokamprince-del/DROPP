import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Redis } from 'ioredis';

import { RealtimeService } from '../realtime/realtime.service.js';
import { REDIS_CLIENT } from '../redis/redis.provider.js';
import { cleRevocationSession, cleRevocationUtilisateur } from './revocation.js';

/**
 * Invalide immédiatement des jetons d'accès encore valides (JWT sans état).
 * Les marqueurs vivent le temps d'un jeton d'accès : au-delà, il a expiré.
 */
@Injectable()
export class RevocationService {
  private readonly logger = new Logger(RevocationService.name);
  private readonly dureeSecondes: number;

  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    private readonly realtime: RealtimeService,
    config: ConfigService,
  ) {
    this.dureeSecondes =
      config.getOrThrow<number>('auth.accessTokenTtlSeconds') + 60;
  }

  /** Tous les jetons déjà émis pour cet utilisateur + ses sockets temps réel. */
  async revoquerUtilisateur(utilisateurId: string): Promise<void> {
    const maintenant = Math.floor(Date.now() / 1000);
    await this.redis
      .set(cleRevocationUtilisateur(utilisateurId), String(maintenant), 'EX', this.dureeSecondes)
      .catch((e: unknown) => this.logger.error(`Révocation ${utilisateurId} : ${String(e)}`));
    this.realtime.deconnecter(utilisateurId);
  }

  /** Les jetons d'une session précise (déconnexion d'un appareil). */
  async revoquerSessions(sessionIds: string[]): Promise<void> {
    if (sessionIds.length === 0) return;
    const pipeline = this.redis.pipeline();
    for (const id of sessionIds) {
      pipeline.set(cleRevocationSession(id), '1', 'EX', this.dureeSecondes);
    }
    await pipeline
      .exec()
      .catch((e: unknown) => this.logger.error(`Révocation sessions : ${String(e)}`));
  }
}
