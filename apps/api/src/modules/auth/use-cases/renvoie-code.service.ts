import { Injectable, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { OtpService } from '../services/otp.service.js';
import { NotificationService } from '../services/notification.service.js';
import { TelephoneService } from '../services/telephone.service.js';
import type { RenvoiCodeDto } from '../dto/renvoi-code.dto.js';
import type { TypeCodeVerification } from '../../../generated/prisma/enums.js';

@Injectable()
export class RenvoiCodeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    private readonly notificationService: NotificationService,
    private readonly telephoneService: TelephoneService,
  ) {}

  /**
   * Renvoie un OTP sur la destination indiquée.
   * Réponse toujours identique qu'un compte existe ou non : anti-énumération.
   * Le cooldown et le plafond horaire sont gérés dans OtpService.
   */
  async executer(dto: RenvoiCodeDto): Promise<void> {
    const estEmail = dto.destination.includes('@');
    const destination = estEmail
      ? dto.destination.trim().toLowerCase()
      : this.telephoneService.normaliser(dto.destination.trim());

    const utilisateur = await this.prisma.utilisateur.findFirst({
      where: estEmail ? { email: destination } : { telephone: destination },
      select: {
        id: true,
        statutCompte: true,
        email: true,
        telephone: true,
      },
    });

    // Compte inexistant ou définitivement supprimé : on sort silencieusement.
    // On NE lève pas d'exception pour ne pas révéler l'existence du compte.
    if (
      !utilisateur ||
      utilisateur.statutCompte === 'SUPPRIME' ||
      utilisateur.statutCompte === 'SUSPENDU_DEF'
    ) {
      return;
    }

    // Déterminer le type d'OTP à renvoyer selon le statut du compte.
    // Un compte EN_ATTENTE_VERIFICATION attend forcément un code d'inscription.
    // Un compte ACTIF qui renvoie un code est en cours de réinitialisation MDP.
    const type: TypeCodeVerification =
      utilisateur.statutCompte === 'EN_ATTENTE_VERIFICATION'
        ? 'INSCRIPTION'
        : 'REINITIALISATION_MOT_DE_PASSE';

    // Canal préféré : email si disponible, sinon SMS
    const canal = utilisateur.email ? 'EMAIL' : 'SMS';
    const canalDestination =
      canal === 'EMAIL' ? utilisateur.email! : utilisateur.telephone!;

    // OtpService lève HttpException 429 si cooldown ou plafond atteint.
    // On laisse l'exception se propager : c'est une information légitime.
    const { code } = await this.otpService.generer({
      destination: canalDestination,
      canal,
      type,
      utilisateurId: utilisateur.id,
    });

    await this.notificationService.envoyerOtp({
      destination: canalDestination,
      canal,
      code,
      type: type === 'INSCRIPTION' ? 'inscription' : 'reinitialisation',
    });
  }
}
