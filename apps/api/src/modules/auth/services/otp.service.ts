import {
  BadRequestException,
  GoneException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
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
 */
interface OtpPayload {
  codeHash: string;
  tentatives: number;
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

  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    private readonly config: ConfigService,
  ) {
    this.pepper = config.getOrThrow<string>('auth.otpPepper');
    this.ttl = config.getOrThrow<number>('redis.otpTtl');
    this.cooldown = config.getOrThrow<number>('redis.otpCooldown');
    this.maxTentatives = config.getOrThrow<number>('redis.otpMaxTentatives');
    this.maxEnvoisHeure = config.getOrThrow<number>('redis.otpMaxEnvoisHeure');
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

    // 1. Vérifier le cooldown
    const cooldownKey = this.cle('cooldown', destination, type);
    const enCooldown = await this.redis.exists(cooldownKey);
    if (enCooldown) {
      const ttlRestant = await this.redis.ttl(cooldownKey);
      throw new HttpException(
        `Attendez ${ttlRestant} seconde(s) avant de renvoyer le code.`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // 2. Vérifier le plafond horaire
    const compteurKey = this.cle('count', destination, type);
    const envoisCetteHeure = await this.redis.get(compteurKey);
    if (Number(envoisCetteHeure ?? 0) >= this.maxEnvoisHeure) {
      throw new HttpException(
        'Trop de codes demandés. Réessayez dans une heure.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // 3. Générer le code et le stocker
    const code = String(randomInt(0, 10 ** OTP_DIGITS)).padStart(
      OTP_DIGITS,
      '0',
    );
    const payload: OtpPayload = {
      codeHash: this.hacher(code, destination),
      tentatives: 0,
      canal,
      ...(utilisateurId ? { utilisateurId } : {}),
    };

    const otpKey = this.cle('otp', destination, type);

    // Pipeline : toutes les opérations en une seule aller-retour Redis
    await this.redis
      .pipeline()
      // Stocker l'OTP avec TTL
      .set(otpKey, JSON.stringify(payload), 'EX', this.ttl)
      // Démarrer le cooldown
      .set(cooldownKey, '1', 'EX', this.cooldown)
      // Incrémenter le compteur horaire
      .incr(compteurKey)
      // TTL du compteur : 1 heure si pas encore défini
      .expire(compteurKey, 3600, 'NX')
      .exec();

    const expiresAt = new Date(Date.now() + this.ttl * 1000);
    return { code, expiresAt };
  }

  /**
   * Vérifie le code soumis par l'utilisateur.
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

    const brut = await this.redis.get(otpKey);
    if (!brut) {
      throw new BadRequestException('Code invalide ou expiré.');
    }

    const payload = JSON.parse(brut) as OtpPayload;

    if (payload.tentatives >= this.maxTentatives) {
      await this.redis.del(otpKey);
      throw new GoneException('Trop de tentatives. Demandez un nouveau code.');
    }

    const attendu = Buffer.from(this.hacher(codeSoumis, destination));
    const stocke = Buffer.from(payload.codeHash);
    const correct =
      attendu.length === stocke.length && timingSafeEqual(attendu, stocke);

    if (!correct) {
      // Incrémenter les tentatives
      payload.tentatives += 1;
      const ttlRestant = await this.redis.ttl(otpKey);
      await this.redis.set(otpKey, JSON.stringify(payload), 'EX', ttlRestant);

      const restantes = this.maxTentatives - payload.tentatives;
      throw new BadRequestException(
        `Code incorrect. ${restantes} tentative(s) restante(s).`,
      );
    }

    // Succès : invalider le code immédiatement
    await this.redis.del(otpKey);

    return { utilisateurId: payload.utilisateurId };
  }

  /**
   * Retourne l'utilisateurId associé à un OTP actif sans le consommer.
   * Utilisé pour valider le verificationToken avant de renvoyer un code.
   */
  async lireUtilisateurId(
    destination: string,
    type: TypeCodeVerification,
  ): Promise<string | undefined> {
    const otpKey = this.cle('otp', destination, type);
    const brut = await this.redis.get(otpKey);
    if (!brut) return undefined;
    return (JSON.parse(brut) as OtpPayload).utilisateurId;
  }

  private hacher(code: string, destination: string): string {
    return createHmac('sha256', this.pepper)
      .update(`${code}:${destination}`)
      .digest('hex');
  }

  private cle(
    prefixe: 'otp' | 'cooldown' | 'count',
    destination: string,
    type: TypeCodeVerification,
  ): string {
    return `dropp:${prefixe}:${type}:${destination}`;
  }
}
