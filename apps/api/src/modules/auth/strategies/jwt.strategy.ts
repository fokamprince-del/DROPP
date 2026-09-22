import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

import type { PayloadJwt } from '../services/jeton.service.js';
import { UtilisateurConnecte } from '../types/utilisateur-connecte.js';



const STATUTS_AUTORISES = new Set(['ACTIF', 'EN_ATTENTE_VERIFICATION']);

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.getOrThrow<string>('jwt.accessSecret'),
      algorithms: ['HS256'],
    });
  }

  /**
   * Appelé après vérification de la signature.
   * Pas de requête en base : le JWT est stateless.
   * La révocation de compte prend effet à l'expiration du token (15 min max).
   * Pour les actions sensibles, utilisez @RequiertReauthentification().
   */
  validate(payload: PayloadJwt): UtilisateurConnecte {
    if (!STATUTS_AUTORISES.has(payload.statutCompte)) {
      throw new UnauthorizedException('Compte indisponible.');
    }
    return {
      id: payload.sub,
      statutCompte: payload.statutCompte,
      telephoneVerifie: payload.tel,
    };
  }
}