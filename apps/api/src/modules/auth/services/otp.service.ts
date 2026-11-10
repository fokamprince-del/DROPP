import {
  BadRequestException,
  GoneException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';
import type { Redis } from 'ioredis';

import { REDIS_CLIENT } from '../../../infrastructure/redis/redis.provider.js';
import type {
  CanalVerification,
  TypeCodeVerification,
} from '@dropp/database';

const OTP_DIGITS = 6;

/**
 * Structure stockée dans Redis pour chaque OTP actif.
 * Le nombre de tentatives est un compteur séparé (INCR atomique).
 */
interface OtpPayload {
  codeHash: string;
  utilisateurId?: string;
  canal: CanalVerification;
}

@Injectable()
export class OtpService {
  private readonly pepper: string;
  private readonly ttl: number;
  private readonly cooldown: number;
  private readonly maxTentatives: number;
  private readonly maxEnvoisHeure: number;
  /** Mode test : code fixe pour ces destinations (bêta sans SMS). */
  private readonly codeTest: string;
  private readonly destinationsTest: ReadonlySet<string>;

  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    config: ConfigService,
  ) {
    this.pepper = config.getOrThrow<string>('auth.otpPepper');
    this.ttl = config.getOrThrow<number>('redis.otpTtl');
    this.cooldown = config.getOrThrow<number>('redis.otpCooldown');
    this.maxTentatives = config.getOrThrow<number>('redis.otpMaxTentatives');
    this.maxEnvoisHeure = config.getOrThrow<number>('redis.otpMaxEnvoisHeure');

    this.codeTest = config.getOrThrow<string>('auth.otpTestCode') ?? '';
    const destinations =
      config.getOrThrow<string[]>('auth.otpTestDestinations') ?? [];
    this.destinationsTest = new Set(
      this.codeTest ? destinations.map((d) => d.toLowerCase()) : [],
    );
    if (this.destinationsTest.size > 0) {
      new Logger(OtpService.name).warn(
        `MODE TEST OTP ACTIF : code fixe pour ${this.destinationsTest.size} destination(s). À désactiver avant l'ouverture publique.`,
      );
    }
  }

  /**
   * Génère un OTP, respecte le cooldown et le plafond horaire.
   * Retourne le code EN CLAIR — à envoyer par SMS/email, jamais à stocker.
   */
  async generer(params: {
    destination: string;
    canal: CanalVerification;
    type: TypeCodeVerification;
    utilisateurId?: string;
  }): Promise<{ code: string; expiresAt: Date }> {
    const { destination, canal, type, utilisateurId } = params;

    // 1. Cooldown : posé atomiquement (SET NX), deux requêtes simultanées
    //    ne peuvent pas envoyer deux codes.
    const cooldownKey = this.cle('cooldown', destination, type);
    const pose = await this.redis.set(cooldownKey, '1', 'EX', this.cooldown, 'NX');
    if (pose !== 'OK') {
      const ttlRestant = Math.max(await this.redis.ttl(cooldownKey), 1);
      throw new HttpException(
        `Attendez ${ttlRestant} seconde(s) avant de renvoyer le code.`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // 2. Plafond horaire : incrémenté avant l'envoi.
    const compteurKey = this.cle('count', destination, type);
    const [[, envois]] = (await this.redis
      .pipeline()
      .incr(compteurKey)
      .expire(compteurKey, 3600, 'NX')
      .exec()) as [[Error | null, number], [Error | null, number]];
    if (envois > this.maxEnvoisHeure) {
      throw new HttpException(
        'Trop de codes demandés. Réessayez dans une heure.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // 3. Nouveau code : remplace le précédent et remet les tentatives à zéro.
    //    Mode test : code fixe pour les destinations autorisées uniquement.
    const code = this.destinationsTest.has(destination.toLowerCase())
      ? this.codeTest
      : String(randomInt(0, 10 ** OTP_DIGITS)).padStart(OTP_DIGITS, '0');
    const payload: OtpPayload = {
      codeHash: this.hacher(code, destination),
      canal,
      ...(utilisateurId ? { utilisateurId } : {}),
    };
    await this.redis
      .pipeline()
      .set(this.cle('otp', destination, type), JSON.stringify(payload), 'EX', this.ttl)
      .del(this.cle('essais', destination, type))
      .exec();

    return { code, expiresAt: new Date(Date.now() + this.ttl * 1000) };
  }

  /**
   * Vérifie le code soumis par l'utilisateur.
   * La tentative est comptée AVANT la comparaison (INCR atomique) : des
   * requêtes parallèles ne peuvent pas dépasser le nombre d'essais autorisé.
   * @throws BadRequestException  code invalide ou expiré.
   * @throws GoneException        trop de tentatives.
   */
  async verifier(params: {
    destination: string;
    type: TypeCodeVerification;
    codeSoumis: string;
  }): Promise<{ utilisateurId?: string }> {
    const { destination, type, codeSoumis } = params;
    const otpKey = this.cle('otp', destination, type);
    const essaisKey = this.cle('essais', destination, type);

    const brut = await this.redis.get(otpKey);
    if (!brut) {
      throw new BadRequestException('Code invalide ou expiré.');
    }

    const [[, essais]] = (await this.redis
      .pipeline()
      .incr(essaisKey)
      .expire(essaisKey, this.ttl, 'NX')
      .exec()) as [[Error | null, number], [Error | null, number]];
    if (essais > this.maxTentatives) {
      await this.redis.del(otpKey, essaisKey);
      throw new GoneException('Trop de tentatives. Demandez un nouveau code.');
    }

    const payload = JSON.parse(brut) as OtpPayload;
    const attendu = Buffer.from(this.hacher(codeSoumis, destination));
    const stocke = Buffer.from(payload.codeHash);
    const correct =
      attendu.length === stocke.length && timingSafeEqual(attendu, stocke);

    if (!correct) {
      const restantes = this.maxTentatives - essais;
      if (restantes <= 0) await this.redis.del(otpKey, essaisKey);
      throw new BadRequestException(
        restantes > 0
          ? `Code incorrect. ${restantes} tentative(s) restante(s).`
          : 'Code incorrect. Demandez un nouveau code.',
      );
    }

    // Usage unique : seule la requête qui supprime effectivement la clé gagne.
    const supprime = await this.redis.del(otpKey);
    await this.redis.del(essaisKey);
    if (supprime === 0) {
      throw new BadRequestException('Code invalide ou expiré.');
    }

    return { utilisateurId: payload.utilisateurId };
  }

  private hacher(code: string, destination: string): string {
    return createHmac('sha256', this.pepper)
      .update(`${code}:${destination}`)
      .digest('hex');
  }

  private cle(
    prefixe: 'otp' | 'cooldown' | 'count' | 'essais',
    destination: string,
    type: TypeCodeVerification,
  ): string {
    return `dropp:${prefixe}:${type}:${destination}`;
  }
}
