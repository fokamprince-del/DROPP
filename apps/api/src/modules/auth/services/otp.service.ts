import {
  BadRequestException,
  GoneException,
  HttpException,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';

import type { CanalVerification, TypeCodeVerification } from '../../../generated/prisma/enums.js';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

const OTP_DIGITS = 6;
const MAX_TENTATIVES = 5;
const COOLDOWN_SECONDES = 60;
const TTL_MINUTES = 5;
const MAX_ENVOIS_PAR_HEURE = 5;

@Injectable()
export class OtpService {
  private readonly pepper: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.pepper = config.getOrThrow<string>('auth.otpPepper');
  }

  /**
   * Génère un OTP, invalide les anciens, respecte cooldown et plafond horaire.
   * Retourne le code EN CLAIR — à envoyer par SMS/email, jamais à stocker.
   */
  async generer(params: {
    destination: string;
    canal: CanalVerification;
    type: TypeCodeVerification;
    utilisateurId?: string;
  }): Promise<{ code: string; expiresAt: Date }> {
    const { destination, canal, type, utilisateurId } = params;
    const maintenant = new Date();

    const dernierCode = await this.prisma.codeVerification.findFirst({
      where: {
        destination,
        type,
        dateUtilisation: null,
        dateExpiration: { gt: maintenant },
      },
      orderBy: { dateCreation: 'desc' },
      select: { cooldownFin: true },
    });

    if (dernierCode?.cooldownFin && dernierCode.cooldownFin > maintenant) {
      const attente = Math.ceil(
        (dernierCode.cooldownFin.getTime() - maintenant.getTime()) / 1000,
      );
      throw new HttpException(
        `Attendez ${attente} seconde(s) avant de renvoyer le code.`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const ilYaUneHeure = new Date(maintenant.getTime() - 3_600_000);
    const envoisCetteHeure = await this.prisma.codeVerification.count({
      where: { destination, type, dateCreation: { gt: ilYaUneHeure } },
    });

    if (envoisCetteHeure >= MAX_ENVOIS_PAR_HEURE) {
      throw new HttpException(
        'Trop de codes demandés. Réessayez dans une heure.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // Invalider les anciens codes actifs sur cette destination
    await this.prisma.codeVerification.updateMany({
      where: { destination, type, dateUtilisation: null },
      data: { dateUtilisation: maintenant },
    });

    const code = String(randomInt(0, 10 ** OTP_DIGITS)).padStart(OTP_DIGITS, '0');
    const expiresAt = new Date(maintenant.getTime() + TTL_MINUTES * 60_000);
    const cooldownFin = new Date(maintenant.getTime() + COOLDOWN_SECONDES * 1_000);

    await this.prisma.codeVerification.create({
      data: {
        destination,
        canal,
        codeHash: this.hacher(code, destination),
        type,
        dateExpiration: expiresAt,
        cooldownFin,
        ...(utilisateurId ? { utilisateurId } : {}),
      },
    });

    return { code, expiresAt };
  }

  /**
   * Vérifie le code soumis. Incrémente les tentatives. Invalide si correct.
   * @throws BadRequestException code invalide ou expiré.
   * @throws GoneException       trop de tentatives.
   */
  async verifier(params: {
    destination: string;
    type: TypeCodeVerification;
    codeSoumis: string;
  }): Promise<void> {
    const { destination, type, codeSoumis } = params;
    const maintenant = new Date();

    const enregistrement = await this.prisma.codeVerification.findFirst({
      where: {
        destination,
        type,
        dateUtilisation: null,
        dateExpiration: { gt: maintenant },
      },
      orderBy: { dateCreation: 'desc' },
    });

    if (!enregistrement) {
      throw new BadRequestException('Code invalide ou expiré.');
    }

    if (enregistrement.nombreTentatives >= MAX_TENTATIVES) {
      await this.prisma.codeVerification.update({
        where: { id: enregistrement.id },
        data: { dateUtilisation: maintenant },
      });
      throw new GoneException('Trop de tentatives. Demandez un nouveau code.');
    }

    const attendu = Buffer.from(this.hacher(codeSoumis, destination));
    const stocke = Buffer.from(enregistrement.codeHash);
    const correct =
      attendu.length === stocke.length && timingSafeEqual(attendu, stocke);

    if (!correct) {
      await this.prisma.codeVerification.update({
        where: { id: enregistrement.id },
        data: { nombreTentatives: { increment: 1 } },
      });
      const restantes = MAX_TENTATIVES - enregistrement.nombreTentatives - 1;
      throw new BadRequestException(
        `Code incorrect. ${restantes} tentative(s) restante(s).`,
      );
    }

    await this.prisma.codeVerification.update({
      where: { id: enregistrement.id },
      data: { dateUtilisation: maintenant },
    });
  }

  private hacher(code: string, destination: string): string {
    return createHmac('sha256', this.pepper)
      .update(`${code}:${destination}`)
      .digest('hex');
  }
}