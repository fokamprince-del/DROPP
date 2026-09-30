import { Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';

import type { CanalVerification } from '../../../generated/prisma/enums.js';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { MotDePasseOublieDto } from '../dto/mot-de-passe-oublie.dto.js';
import { JetonService } from '../services/jeton.service.js';
import { NotificationService } from '../services/notification.service.js';
import { OtpService } from '../services/otp.service.js';
import { TelephoneService } from '../services/telephone.service.js';

/**
 * Étape 1 du mot de passe oublié.
 *
 * Retourne TOUJOURS un verificationToken (à renvoyer avec le code à
 * POST /auth/reinitialiser-mot-de-passe), que le compte existe ou non :
 * la réponse ne révèle pas quels identifiants sont inscrits. Pour un compte
 * inconnu, le token porte un id aléatoire et l'étape 2 échouera comme un
 * mauvais code.
 *
 * Le canal utilisé n'est pas renvoyé (il trahirait l'existence du compte) :
 * l'app affiche « Si un compte existe, un code vous a été envoyé ».
 *
 * Canal : l'email seulement s'il a été VÉRIFIÉ (sinon un code de
 * réinitialisation pourrait partir vers une adresse jamais confirmée),
 * sinon le téléphone.
 */
@Injectable()
export class MotDePasseOublieService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    private readonly notificationService: NotificationService,
    private readonly jetonService: JetonService,
    private readonly telephoneService: TelephoneService,
  ) {}

  async executer(
    dto: MotDePasseOublieDto,
  ): Promise<{ verificationToken: string }> {
    const estEmail = dto.identifiant.includes('@');
    const identifiant = estEmail
      ? dto.identifiant.trim().toLowerCase()
      : this.telephoneService.normaliserOuBrut(dto.identifiant);

    const utilisateur = await this.prisma.utilisateur.findFirst({
      where: estEmail ? { email: identifiant } : { telephone: identifiant },
      select: {
        id: true,
        statutCompte: true,
        telephone: true,
        email: true,
        emailVerifieLe: true,
      },
    });

    const canalDemande: CanalVerification = estEmail ? 'EMAIL' : 'SMS';

    const eligible =
      utilisateur &&
      utilisateur.statutCompte !== 'SUPPRIME' &&
      utilisateur.statutCompte !== 'SUSPENDU_DEF';

    if (!eligible) {
      // Réponse indiscernable d'un compte existant.
      return {
        verificationToken: this.jetonService.signerVerification({
          sub: randomUUID(),
          dst: identifiant,
          canalOtp: canalDemande,
          purpose: 'reinitialisation',
        }),
      };
    }

    const parEmail = Boolean(utilisateur.email && utilisateur.emailVerifieLe);
    const canal: CanalVerification =
      parEmail && (estEmail || !utilisateur.telephone) ? 'EMAIL' : 'SMS';
    const destination =
      canal === 'EMAIL' ? utilisateur.email! : utilisateur.telephone!;

    const { code } = await this.otpService.generer({
      destination,
      canal,
      type: 'REINITIALISATION_MOT_DE_PASSE',
      utilisateurId: utilisateur.id,
    });

    await this.notificationService.envoyerOtp({
      destination,
      canal,
      code,
      type: 'reinitialisation',
    });

    await this.prisma.journalSecurite
      .create({
        data: {
          utilisateurId: utilisateur.id,
          evenement: 'REINITIALISATION_MDP_DEMANDEE',
          details: { canal },
        },
      })
      .catch(() => undefined);

    return {
      verificationToken: this.jetonService.signerVerification({
        sub: utilisateur.id,
        dst: destination,
        canalOtp: canal,
        purpose: 'reinitialisation',
      }),
    };
  }
}
