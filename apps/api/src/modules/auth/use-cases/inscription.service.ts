import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import type { Redis } from 'ioredis';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { REDIS_CLIENT } from '../../../infrastructure/redis/redis.provider.js';
import { OtpService } from '../services/otp.service.js';
import { MotDePasseService } from '../services/mot-de-passe.service.js';
import { TelephoneService } from '../services/telephone.service.js';
import { NotificationService } from '../services/notification.service.js';
import type { InscriptionDto } from '../dto/inscription.dto.js';
import { JetonService } from '../services/jeton.service.js';

/** Un avertissement « compte existant » au plus par destination et par heure. */
const DELAI_AVERTISSEMENT_S = 3600;

/**
 * Inscription sans énumération des comptes : la réponse est toujours un
 * verificationToken, que le numéro soit libre ou non.
 * - Numéro libre : compte créé, code SMS envoyé.
 * - Numéro d'une inscription jamais vérifiée : l'inscription est reprise
 *   (rien n'a été prouvé sur ce compte) et un nouveau code est envoyé.
 * - Numéro d'un compte vérifié : le titulaire reçoit un SMS l'informant
 *   qu'un compte existe ; le token renvoyé ne mènera à rien.
 * - Email déjà utilisé : ignoré (non enregistré), son titulaire est prévenu.
 */
@Injectable()
export class InscriptionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly motDePasseService: MotDePasseService,
    private readonly otpService: OtpService,
    private readonly telephoneService: TelephoneService,
    private readonly notificationService: NotificationService,
    private readonly jetonService: JetonService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  async executer(dto: InscriptionDto): Promise<{ verificationToken: string }> {
    const telephone = this.telephoneService.normaliser(dto.telephone);
    const emailDemande = dto.email ? dto.email.trim().toLowerCase() : null;

    // Validation + hachage dans tous les cas : même temps de réponse.
    const motDePasseHash = await this.motDePasseService.hacher(dto.motDePasse);

    const [parTelephone, parEmail] = await Promise.all([
      this.prisma.utilisateur.findUnique({
        where: { telephone },
        select: { id: true, statutCompte: true, telephoneVerifieLe: true },
      }),
      emailDemande
        ? this.prisma.utilisateur.findUnique({
            where: { email: emailDemande },
            select: { id: true },
          })
        : null,
    ]);

    const inscriptionAbandonnee =
      parTelephone?.statutCompte === 'EN_ATTENTE_VERIFICATION' &&
      parTelephone.telephoneVerifieLe === null;

    if (parTelephone && !inscriptionAbandonnee) {
      await this.avertir(
        telephone,
        'SMS',
        'Un compte DROPP existe déjà avec ce numéro. Connectez-vous ou utilisez « Mot de passe oublié ».',
      );
      return { verificationToken: this.tokenFactice(telephone) };
    }

    // Email pris par un autre compte : on ne l'enregistre pas.
    const emailPris = parEmail !== null && parEmail.id !== parTelephone?.id;
    if (emailPris && emailDemande) {
      await this.avertir(
        emailDemande,
        'EMAIL',
        'Quelqu’un a tenté de créer un compte DROPP avec votre adresse email. Si c’était vous, connectez-vous à votre compte existant.',
      );
    }
    const email = emailPris ? null : emailDemande;

    const donnees = {
      prenom: dto.prenom.trim(),
      nom: dto.nom.trim(),
      email,
      motDePasseHash,
      sexe: dto.sexe,
    };
    const utilisateur = parTelephone
      ? await this.prisma.utilisateur.update({
          where: { id: parTelephone.id },
          data: { ...donnees, emailVerifieLe: null },
          select: { id: true },
        })
      : await this.prisma.utilisateur.create({
          data: { ...donnees, telephone, client: { create: {} } },
          select: { id: true },
        });

    // Activation par SMS : c'est le TÉLÉPHONE que ce code vérifie (un compte
    // ACTIF exige telephone_verifie_le). L'email, s'il est fourni, est
    // confirmé séparément après l'activation (VerificationEmailService).
    const { code } = await this.otpService.generer({
      destination: telephone,
      canal: 'SMS',
      type: 'INSCRIPTION',
      utilisateurId: utilisateur.id,
    });
    await this.notificationService.envoyerOtp({
      destination: telephone,
      canal: 'SMS',
      code,
      type: 'inscription',
    });

    return {
      verificationToken: this.jetonService.signerVerification({
        sub: utilisateur.id,
        dst: telephone,
        canalOtp: 'SMS',
        purpose: 'inscription',
      }),
    };
  }

  /** Token de même forme qu'un vrai : la vérification échouera comme un mauvais code. */
  private tokenFactice(telephone: string): string {
    return this.jetonService.signerVerification({
      sub: randomUUID(),
      dst: telephone,
      canalOtp: 'SMS',
      purpose: 'inscription',
    });
  }

  private async avertir(
    destination: string,
    canal: 'SMS' | 'EMAIL',
    message: string,
  ): Promise<void> {
    const premier = await this.redis.set(
      `dropp:avertissement-inscription:${destination}`,
      '1',
      'EX',
      DELAI_AVERTISSEMENT_S,
      'NX',
    );
    if (premier !== 'OK') return;
    await this.notificationService.envoyerMessage({
      destination,
      canal,
      sujet: 'Tentative d’inscription sur DROPP',
      message,
    });
  }
}
