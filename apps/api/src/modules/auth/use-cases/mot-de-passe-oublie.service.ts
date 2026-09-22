import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { OtpService } from '../services/otp.service.js';
import { NotificationService } from '../services/notification.service.js';
import type { MotDePasseOublieDto } from '../dto/mot-de-passe-oublie.dto.js';

@Injectable()
export class MotDePasseOublieService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    private readonly notificationService: NotificationService,
  ) {}

  /**
   * Réponse toujours identique : anti-énumération.
   * L'OTP est envoyé seulement si le compte existe et a un identifiant correspondant.
   */
  async executer(dto: MotDePasseOublieDto): Promise<void> {
    const estEmail = dto.identifiant.includes('@');
    const identifiantNormalise = estEmail
      ? dto.identifiant.trim().toLowerCase()
      : dto.identifiant.trim();

    const utilisateur = await this.prisma.utilisateur.findFirst({
      where: estEmail
        ? { email: identifiantNormalise }
        : { telephone: identifiantNormalise },
      select: {
        id: true,
        statutCompte: true,
        telephone: true,
        email: true,
      },
    });

    // Même si introuvable : on ne révèle rien, on sort silencieusement
    if (
      !utilisateur ||
      utilisateur.statutCompte === 'SUPPRIME' ||
      utilisateur.statutCompte === 'SUSPENDU_DEF'
    ) {
      return;
    }

    // Canal préféré : email si disponible, sinon SMS
    const canal = utilisateur.email ? 'EMAIL' : 'SMS';
    const destination = canal === 'EMAIL' ? utilisateur.email! : utilisateur.telephone!;

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
  }
}