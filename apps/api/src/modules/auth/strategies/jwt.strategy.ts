import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import {
  ExtractJwt,
  Strategy,
} from 'passport-jwt';

import { UtilisateurAuthentifie } from '../types/user-authentified.type.js';

interface JwtPayload {
  sub: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    configService: ConfigService,
  ) {
    super({
      jwtFromRequest:
        ExtractJwt.fromAuthHeaderAsBearerToken(),

      ignoreExpiration: false,

      secretOrKey:
        configService.getOrThrow<string>(
          'jwt.accessSecret',
        ),
    });
  }

  async validate(
    payload: JwtPayload,
  ): Promise<UtilisateurAuthentifie> {
    return {
      utilisateurId: payload.sub,
    };
  }
}