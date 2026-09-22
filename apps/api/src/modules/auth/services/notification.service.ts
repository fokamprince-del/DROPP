import { Inject, Injectable, Logger } from '@nestjs/common';

import type { CanalVerification } from '../../../generated/prisma/enums.js';
import {
  NOTIFICATION_PROVIDER,
  type NotificationProvider,
} from '../../../infrastructure/notification/notification-provider.contract.js';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @Inject(NOTIFICATION_PROVIDER)
    private readonly provider: NotificationProvider,
  ) {}

  /**
   * Envoie un OTP sur le canal disponible.
   * Les erreurs sont loguées mais ne propagent pas :
   * un OTP non reçu peut être renvoyé.
   */
  async envoyerOtp(params: {
    destination: string;
    canal: CanalVerification;
    code: string;
    type: 'inscription' | 'connexion' | 'reinitialisation' | 'verification';
  }): Promise<void> {
    const { destination, canal, code, type } = params;

    const messages: Record<typeof type, string> = {
      inscription: `Votre code d'inscription DROPP : ${code}. Valable 5 minutes.`,
      connexion: `Votre code de connexion DROPP : ${code}. Valable 5 minutes.`,
      reinitialisation: `Votre code de réinitialisation DROPP : ${code}. Valable 5 minutes.`,
      verification: `Votre code de vérification DROPP : ${code}. Valable 5 minutes.`,
    };

    try {
      if (canal === 'EMAIL') {
        await this.provider.envoyerEmail(
          destination,
          'Votre code DROPP',
          messages[type],
        );
      } else {
        await this.provider.envoyerSms(destination, messages[type]);
      }
    } catch (erreur) {
      this.logger.error(
        `Échec envoi OTP [${canal}] → ${destination} : ${String(erreur)}`,
      );
    }
  }
}