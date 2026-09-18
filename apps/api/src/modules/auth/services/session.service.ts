import {
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { randomBytes } from 'node:crypto';
import * as argon2 from 'argon2';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

interface CreerSessionParams {
  utilisateurId: string;
  adresseIp?: string;
  appareilId?: string;
}

interface SessionToken {
  sessionId: string;
  secret: string;
}

@Injectable()
export class SessionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async creerSession(
    params: CreerSessionParams,
  ) {
    const secret = this.genererSecret();

    const familleJeton =
      randomBytes(32).toString('hex');

    const hash =
      await this.hacherRefreshToken(secret);

    const dateExpiration = new Date(
      Date.now() +
        this.dureeRefreshTokenMs(),
    );

    const session =
      await this.prisma.session.create({
        data: {
          utilisateurId:
            params.utilisateurId,

          jetonRafraichissementHash:
            hash,

          familleJeton,

          dateExpiration,

          adresseIpCreation:
            params.adresseIp,

          appareilId:
            params.appareilId,
        },
      });

    const accessToken =
      await this.creerAccessToken(
        params.utilisateurId,
      );

    return {
      accessToken,

      refreshToken:
        this.construireRefreshToken(
          session.id,
          secret,
        ),

      sessionId: session.id,
    };
  }

  async renouvelerSession(
    refreshToken: string,
  ) {
    const token =
      this.decoderRefreshToken(
        refreshToken,
      );

    if (!token) {
      throw new UnauthorizedException(
        'Jeton de renouvellement invalide.',
      );
    }

    return this.prisma.$transaction(
      async (tx) => {
        const sessions =
          await tx.$queryRaw<
            Array<{
              id: string;
              utilisateur_id: string;
              jeton_rafraichissement_hash: string;
              famille_jeton: string;
              date_expiration: Date;
              date_revocation: Date | null;
            }>
          >`
            SELECT
              id,
              utilisateur_id,
              jeton_rafraichissement_hash,
              famille_jeton,
              date_expiration,
              date_revocation
            FROM sessions
            WHERE id = ${token.sessionId}::uuid
            FOR UPDATE
          `;

        const session = sessions[0];

        if (
          !session ||
          session.date_revocation !== null ||
          session.date_expiration <= new Date()
        ) {
          throw new UnauthorizedException(
            'Jeton de renouvellement invalide.',
          );
        }

        const valide =
          await argon2.verify(
            session.jeton_rafraichissement_hash,
            token.secret,
          );

        if (!valide) {
          await tx.session.updateMany({
            where: {
              familleJeton:
                session.famille_jeton,

              dateRevocation: null,
            },

            data: {
              dateRevocation: new Date(),
            },
          });

          throw new UnauthorizedException(
            'Jeton de renouvellement invalide.',
          );
        }

        const nouveauSecret =
          this.genererSecret();

        const nouveauHash =
          await this.hacherRefreshToken(
            nouveauSecret,
          );

        await tx.session.update({
          where: {
            id: token.sessionId,
          },

          data: {
            jetonRafraichissementHash:
              nouveauHash,

            dateDerniereUtilisation:
              new Date(),
          },
        });

        const accessToken =
          await this.creerAccessToken(
            session.utilisateur_id,
          );

        return {
          accessToken,

          refreshToken:
            this.construireRefreshToken(
              session.id,
              nouveauSecret,
            ),

          sessionId: session.id,
        };
      },
    );
  }

  async revoquerSession(
    sessionId: string,
  ): Promise<void> {
    await this.prisma.session.updateMany({
      where: {
        id: sessionId,
        dateRevocation: null,
      },

      data: {
        dateRevocation: new Date(),
      },
    });
  }

  async revoquerToutesLesSessions(
    utilisateurId: string,
  ): Promise<void> {
    await this.prisma.session.updateMany({
      where: {
        utilisateurId,
        dateRevocation: null,
      },

      data: {
        dateRevocation: new Date(),
      },
    });
  }

  private async creerAccessToken(
    utilisateurId: string,
  ): Promise<string> {
    return this.jwtService.signAsync({
      sub: utilisateurId,
    });
  }

  private genererSecret(): string {
    return randomBytes(64).toString(
      'base64url',
    );
  }

  private async hacherRefreshToken(
    secret: string,
  ): Promise<string> {
    return argon2.hash(secret, {
      type: argon2.argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 4,
    });
  }

  private construireRefreshToken(
    sessionId: string,
    secret: string,
  ): string {
    return `${sessionId}.${secret}`;
  }

  private decoderRefreshToken(
    refreshToken: string,
  ): SessionToken | null {
    const separatorIndex =
      refreshToken.indexOf('.');

    if (separatorIndex <= 0) {
      return null;
    }

    const sessionId =
      refreshToken.slice(
        0,
        separatorIndex,
      );

    const secret =
      refreshToken.slice(
        separatorIndex + 1,
      );

    if (!secret) {
      return null;
    }

    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

    if (!uuidRegex.test(sessionId)) {
      return null;
    }

    return {
      sessionId,
      secret,
    };
  }

  private dureeRefreshTokenMs(): number {
    const ttl =
      this.configService.getOrThrow<string>(
        'refreshToken.ttl',
      );

    const match =
      ttl.match(/^(\d+)([smhd])$/);

    if (!match) {
      throw new Error(
        'REFRESH_TOKEN_TTL possède un format invalide.',
      );
    }

    const valeur = Number(match[1]);
    const unite = match[2];

    const multiplicateurs = {
      s: 1000,
      m: 60 * 1000,
      h: 60 * 60 * 1000,
      d: 24 * 60 * 60 * 1000,
    } as const;

    return (
      valeur *
      multiplicateurs[
        unite as keyof typeof multiplicateurs
      ]
    );
  }
}