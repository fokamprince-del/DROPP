import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { createHash, randomBytes } from 'node:crypto';

import type {
  CanalVerification,
  MethodeAuthentification,
} from '@dropp/database';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { RevocationService } from '../../../infrastructure/revocation/revocation.service.js';

export interface PayloadJwt {
  sub: string;
  /** Session (refresh token) ayant émis ce jeton : permet de le révoquer. */
  sid?: string;
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

/** Statuts qui autorisent l'obtention de nouveaux jetons. */
const STATUTS_AUTORISES = new Set(['ACTIF', 'EN_ATTENTE_VERIFICATION']);

@Injectable()
export class JetonService {
  private readonly refreshTtlMs: number;
  private readonly accessTtl: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly revocation: RevocationService,
  ) {
    this.refreshTtlMs =
      config.getOrThrow<number>('auth.refreshTokenTtlSeconds') * 1_000;
    this.accessTtl = config.getOrThrow<number>('auth.accessTokenTtlSeconds');
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

    // Révoquer les sessions les plus anciennes si le plafond est atteint
    const sessions = await this.prisma.session.findMany({
      where: {
        utilisateurId,
        dateRevocation: null,
        dateExpiration: { gt: new Date() },
      },
      orderBy: { dateCreation: 'asc' },
      select: { id: true },
    });
    const enTrop = sessions
      .slice(0, Math.max(sessions.length - MAX_SESSIONS + 1, 0))
      .map((s) => s.id);
    if (enTrop.length > 0) {
      await this.prisma.session.updateMany({
        where: { id: { in: enTrop } },
        data: { dateRevocation: new Date() },
      });
      await this.revocation.revoquerSessions(enTrop);
    }

    const refreshToken = randomBytes(48).toString('base64url');
    const session = await this.prisma.session.create({
      data: {
        utilisateurId,
        jetonRafraichissementHash: this.hacherRefresh(refreshToken),
        familleJeton: randomBytes(16).toString('hex'),
        methodeAuth,
        adresseIpCreation: adresseIp ?? null,
        appareilId: appareilId ?? null,
        dateExpiration: new Date(Date.now() + this.refreshTtlMs),
        dateDerniereUtilisation: new Date(),
      },
      select: { id: true },
    });

    return this.emettre(
      { sub: utilisateurId, sid: session.id, statutCompte, tel: telephoneVerifie },
      refreshToken,
    );
  }

  /**
   * Rotation avec détection de réutilisation.
   * Un jeton déjà révoqué présenté → toute la famille est révoquée.
   * La révocation de l'ancien jeton est conditionnelle : de deux requêtes
   * simultanées avec le même jeton, une seule obtient de nouveaux jetons.
   */
  async rafraichir(refreshTokenBrut: string): Promise<JetonsEmis> {
    const session = await this.prisma.session.findUnique({
      where: { jetonRafraichissementHash: this.hacherRefresh(refreshTokenBrut) },
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
      await this.compromettreFamille(session.utilisateurId, session.familleJeton);
    }
    if (session.dateExpiration < new Date()) {
      throw new UnauthorizedException('Session expirée. Reconnectez-vous.');
    }

    const { statutCompte, telephoneVerifieLe } = session.utilisateur;
    if (!STATUTS_AUTORISES.has(statutCompte)) {
      await this.revoquerToutesLesSessions(session.utilisateurId);
      throw new UnauthorizedException('Compte indisponible.');
    }

    const nouveauRefresh = randomBytes(48).toString('base64url');
    const nouvelle = await this.prisma.$transaction(async (tx) => {
      const { count } = await tx.session.updateMany({
        where: { id: session.id, dateRevocation: null },
        data: { dateRevocation: new Date() },
      });
      if (count === 0) return null; // une requête concurrente a déjà tourné le jeton
      return tx.session.create({
        data: {
          utilisateurId: session.utilisateurId,
          jetonRafraichissementHash: this.hacherRefresh(nouveauRefresh),
          familleJeton: session.familleJeton,
          methodeAuth: session.methodeAuth,
          adresseIpCreation: session.adresseIpCreation,
          appareilId: session.appareilId,
          dateExpiration: new Date(Date.now() + this.refreshTtlMs),
          dateDerniereUtilisation: new Date(),
        },
        select: { id: true },
      });
    });
    if (!nouvelle) {
      await this.compromettreFamille(session.utilisateurId, session.familleJeton);
    }

    return this.emettre(
      {
        sub: session.utilisateurId,
        sid: nouvelle!.id,
        statutCompte,
        tel: telephoneVerifieLe !== null,
      },
      nouveauRefresh,
    );
  }

  async revoquerSession(
    sessionId: string,
    utilisateurId: string,
  ): Promise<void> {
    await this.prisma.session.updateMany({
      where: { id: sessionId, utilisateurId, dateRevocation: null },
      data: { dateRevocation: new Date() },
    });
    await this.revocation.revoquerSessions([sessionId]);
  }

  async revoquerToutesLesSessions(utilisateurId: string): Promise<void> {
    await this.prisma.session.updateMany({
      where: { utilisateurId, dateRevocation: null },
      data: { dateRevocation: new Date() },
    });
    await this.revocation.revoquerUtilisateur(utilisateurId);
  }

  /** Réutilisation d'un jeton déjà tourné : probable vol. */
  private async compromettreFamille(
    utilisateurId: string,
    familleJeton: string,
  ): Promise<never> {
    await this.prisma.session.updateMany({
      where: { familleJeton },
      data: { dateRevocation: new Date() },
    });
    await this.revocation.revoquerUtilisateur(utilisateurId);
    await this.prisma.journalSecurite
      .create({
        data: {
          utilisateurId,
          evenement: 'REFRESH_REJETE',
          details: { motif: 'reutilisation' },
        },
      })
      .catch(() => undefined);
    throw new UnauthorizedException(
      'Session compromise. Toutes vos sessions ont été révoquées.',
    );
  }

  private emettre(payload: PayloadJwt, refreshToken: string): JetonsEmis {
    return {
      accessToken: this.jwt.sign(payload),
      refreshToken,
      expiresIn: this.accessTtl,
    };
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
      return this.jwt.verify<PayloadVerification>(token, {
        secret,
        algorithms: ['HS256'],
      });
    } catch {
      throw new UnauthorizedException(
        'Token de vérification invalide ou expiré.',
      );
    }
  }
}
