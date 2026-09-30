import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { ChangerEmailDto, VerifierEmailDto } from '../dto/email.dto.js';
import { MotDePasseService } from '../services/mot-de-passe.service.js';
import { NotificationService } from '../services/notification.service.js';
import { OtpService } from '../services/otp.service.js';

const TYPE_OTP = 'VERIFICATION_EMAIL' as const;

/**
 * Vérification de l'adresse email (code à 6 chiffres envoyé par email).
 * - Après l'activation du compte, un code est envoyé automatiquement si un
 *   email a été fourni à l'inscription.
 * - Changement d'adresse : la nouvelle adresse n'est enregistrée qu'une fois
 *   son code saisi (l'ancienne reste active entre-temps).
 */
@Injectable()
export class VerificationEmailService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otp: OtpService,
    private readonly notification: NotificationService,
    private readonly motDePasse: MotDePasseService,
  ) {}

  /** (Re)envoie un code à l'adresse actuelle, si elle n'est pas encore vérifiée. */
  async envoyerCode(utilisateurId: string) {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: { email: true, emailVerifieLe: true },
    });
    if (!utilisateur) throw new NotFoundException('Utilisateur introuvable.');
    if (!utilisateur.email) {
      throw new BadRequestException('Aucune adresse email sur ce compte.');
    }
    if (utilisateur.emailVerifieLe) {
      throw new ConflictException('Cette adresse email est déjà vérifiée.');
    }
    return this.envoyer(utilisateurId, utilisateur.email);
  }

  async changer(utilisateurId: string, dto: ChangerEmailDto) {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: { email: true, motDePasseHash: true },
    });
    if (!utilisateur) throw new NotFoundException('Utilisateur introuvable.');

    if (utilisateur.motDePasseHash) {
      const { valide } = await this.motDePasse.verifier(
        dto.motDePasse ?? '',
        utilisateur.motDePasseHash,
      );
      if (!valide) throw new UnauthorizedException('Mot de passe incorrect.');
    }
    if (utilisateur.email === dto.email) {
      throw new BadRequestException('C’est déjà votre adresse email.');
    }
    const prise = await this.prisma.utilisateur.count({
      where: { email: dto.email },
    });
    if (prise) throw new ConflictException('Cette adresse email est déjà utilisée.');

    return this.envoyer(utilisateurId, dto.email);
  }

  async verifier(utilisateurId: string, dto: VerifierEmailDto) {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: { email: true },
    });
    if (!utilisateur) throw new NotFoundException('Utilisateur introuvable.');

    const email = dto.email ?? utilisateur.email;
    if (!email) {
      throw new BadRequestException('Aucune adresse email à vérifier.');
    }

    const { utilisateurId: proprietaire } = await this.otp.verifier({
      destination: email,
      type: TYPE_OTP,
      codeSoumis: dto.code,
    });
    if (proprietaire !== utilisateurId) {
      throw new ForbiddenException('Code invalide pour ce compte.');
    }

    const changement = email !== utilisateur.email;
    try {
      await this.prisma.$transaction([
        this.prisma.utilisateur.update({
          where: { id: utilisateurId },
          data: { email, emailVerifieLe: new Date() },
        }),
        ...(changement
          ? [
              this.prisma.journalSecurite.create({
                data: { utilisateurId, evenement: 'EMAIL_CHANGE' as const },
              }),
            ]
          : []),
      ]);
    } catch (e) {
      if (
        typeof e === 'object' &&
        e !== null &&
        'code' in e &&
        (e as { code: string }).code === 'P2002'
      ) {
        throw new ConflictException('Cette adresse email est déjà utilisée.');
      }
      throw e;
    }

    return { email, emailVerifie: true };
  }

  private async envoyer(utilisateurId: string, email: string) {
    const { code, expiresAt } = await this.otp.generer({
      destination: email,
      canal: 'EMAIL',
      type: TYPE_OTP,
      utilisateurId,
    });
    await this.notification.envoyerOtp({
      destination: email,
      canal: 'EMAIL',
      code,
      type: 'email',
    });
    return { email, expireA: expiresAt };
  }
}
