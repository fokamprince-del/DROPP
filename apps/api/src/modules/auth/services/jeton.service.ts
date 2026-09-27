import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';

import type {
  CanalVerification,
  MethodeAuthentification,
} from '../../../generated/prisma/enums.js';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

export interface PayloadJwt {
  sub: string;
  statutCompte: string;
  tel: boolean; // telephoneVerifieLe != null
}

export interface JetonsEmis {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface PayloadVerification {
  sub: string; // utilisateurId
  dst: string; // destination (tel ou email)
  canalOtp: CanalVerification;
  purpose: 'inscription' | 'reinitialisation';
}
const MAX_SESSIONS = 5;

@Injectable()
export class JetonService {
  private readonly refreshTtlMs: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {
    this.refreshTtlMs =
      config.getOrThrow<number>('auth.refreshTokenTtlSeconds') * 1_000;
  }

  async ouvrirSession(params: {
    utilisateurId: string;
    statutCompte: string;
    telephoneVerifie: boolean;
    methodeAuth: MethodeAuthentification;
    adresseIp?: string;
    appareilId?: string;
  }): Promise<JetonsEmis> {
    const {
      utilisateurId,
      statutCompte,
      telephoneVerifie,
      methodeAuth,
      adresseIp,
      appareilId,
    } = params;

    // Révoquer la session la plus ancienne si le plafond est atteint
    const sessions = await this.prisma.session.findMany({
      where: {
        utilisateurId,
        dateRevocation: null,
        dateExpiration: { gt: new Date() },
      },
      orderBy: { dateCreation: 'asc' },
      select: { id: true },
    });

    if (sessions.length >= MAX_SESSIONS) {
      await this.prisma.session.update({
        where: { id: sessions[0].id },
        data: { dateRevocation: new Date() },
      });
    }

    const familleJeton = randomBytes(16).toString('hex');
    const refreshToken = randomBytes(48).toString('base64url');
    const expiration = new Date(Date.now() + this.refreshTtlMs);

    await this.prisma.session.create({
      data: {
        utilisateurId,
        jetonRafraichissementHash: this.hacherRefresh(refreshToken),
        familleJeton,
        methodeAuth,
        adresseIpCreation: adresseIp ?? null,
        appareilId: appareilId ?? null,
        dateExpiration: expiration,
      },
    });

    const accessTtl = this.config.getOrThrow<number>(
      'auth.accessTokenTtlSeconds',
    );
    const payload: PayloadJwt = {
      sub: utilisateurId,
      statutCompte,
      tel: telephoneVerifie,
    };

    return {
      accessToken: this.jwt.sign(payload),
      refreshToken,
      expiresIn: accessTtl,
    };
  }

  /**
   * Rotation avec détection de réutilisation.
   * Un jeton déjà révoqué présenté → toute la famille est révoquée.
   */
  async rafraichir(refreshTokenBrut: string): Promise<JetonsEmis> {
    const hash = this.hacherRefresh(refreshTokenBrut);

    const session = await this.prisma.session.findUnique({
      where: { jetonRafraichissementHash: hash },
      include: {
        utilisateur: {
          select: { statutCompte: true, telephoneVerifieLe: true },
        },
      },
    });

    if (!session) {
      throw new UnauthorizedException('Jeton invalide.');
    }

    if (session.dateRevocation !== null) {
      // Réutilisation détectée : probable vol de token
      await this.prisma.session.updateMany({
        where: { familleJeton: session.familleJeton },
        data: { dateRevocation: new Date() },
      });
      throw new UnauthorizedException(
        'Session compromise. Toutes vos sessions ont été révoquées.',
      );
    }

    if (session.dateExpiration < new Date()) {
      throw new UnauthorizedException('Session expirée. Reconnectez-vous.');
    }

    const { statutCompte, telephoneVerifieLe } = session.utilisateur;
    const nouveauRefresh = randomBytes(48).toString('base64url');
    const expiration = new Date(Date.now() + this.refreshTtlMs);

    await this.prisma.$transaction([
      this.prisma.session.update({
        where: { id: session.id },
        data: { dateRevocation: new Date() },
      }),
      this.prisma.session.create({
        data: {
          utilisateurId: session.utilisateurId,
          jetonRafraichissementHash: this.hacherRefresh(nouveauRefresh),
          familleJeton: session.familleJeton,
          methodeAuth: session.methodeAuth,
          adresseIpCreation: session.adresseIpCreation,
          appareilId: session.appareilId,
          dateExpiration: expiration,
        },
      }),
    ]);

    const accessTtl = this.config.getOrThrow<number>(
      'auth.accessTokenTtlSeconds',
    );
    const payload: PayloadJwt = {
      sub: session.utilisateurId,
      statutCompte,
      tel: telephoneVerifieLe !== null,
    };

    return {
      accessToken: this.jwt.sign(payload),
      refreshToken: nouveauRefresh,
      expiresIn: accessTtl,
    };
  }

  async revoquerSession(
    sessionId: string,
    utilisateurId: string,
  ): Promise<void> {
    await this.prisma.session.updateMany({
      where: { id: sessionId, utilisateurId, dateRevocation: null },
      data: { dateRevocation: new Date() },
    });
  }

  async revoquerToutesLesSessions(utilisateurId: string): Promise<void> {
    await this.prisma.session.updateMany({
      where: { utilisateurId, dateRevocation: null },
      data: { dateRevocation: new Date() },
    });
  }

  private hacherRefresh(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  /**
   * Signe un token de vérification court (15min).
   * Secret distinct du JWT d'accès.
   */
  signerVerification(payload: PayloadVerification): string {
    const secret = this.config.getOrThrow<string>('auth.verificationSecret');
    const ttl = this.config.getOrThrow<number>('auth.verificationTtlSeconds');
    return this.jwt.sign(payload, { secret, expiresIn: ttl });
  }

  /**
   * Vérifie et décode un token de vérification.
   * @throws UnauthorizedException si invalide ou expiré.
   */
  verifierTokenVerification(token: string): PayloadVerification {
    const secret = this.config.getOrThrow<string>('auth.verificationSecret');
    try {
      return this.jwt.verify<PayloadVerification>(token, { secret });
    } catch {
      throw new UnauthorizedException(
        'Token de vérification invalide ou expiré.',
      );
    }
  }
}
