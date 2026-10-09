import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import type { Redis } from 'ioredis';
import { ExtractJwt, Strategy } from 'passport-jwt';

import { REDIS_CLIENT } from '../../../infrastructure/redis/redis.provider.js';
import { jetonRevoque } from '../../../infrastructure/revocation/revocation.js';
import type { PayloadJwt } from '../services/jeton.service.js';
import type { UtilisateurConnecte } from '../types/utilisateur-connecte.js';

const STATUTS_AUTORISES = new Set(['ACTIF', 'EN_ATTENTE_VERIFICATION']);

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    config: ConfigService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.getOrThrow<string>('jwt.accessSecret'),
      algorithms: ['HS256'],
    });
  }

  /**
   * Appelé après vérification de la signature. Pas de requête en base :
   * un seul aller-retour Redis vérifie que le jeton n'a pas été révoqué
   * (déconnexion, suspension, suppression, changement de mot de passe).
   */
  async validate(
    payload: PayloadJwt & { iat?: number },
  ): Promise<UtilisateurConnecte> {
    if (!STATUTS_AUTORISES.has(payload.statutCompte)) {
      throw new UnauthorizedException('Compte indisponible.');
    }
    if (await jetonRevoque(this.redis, payload)) {
      throw new UnauthorizedException('Session expirée. Reconnectez-vous.');
    }
    return {
      id: payload.sub,
      statutCompte: payload.statutCompte,
      telephoneVerifie: payload.tel,
      sessionId: payload.sid,
    };
  }
}
