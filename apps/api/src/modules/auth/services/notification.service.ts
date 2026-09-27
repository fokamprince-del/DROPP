import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import type { Queue } from 'bullmq';

import {
  JOB_NOTIFICATION,
  QUEUE_NOTIFICATION,
  type JobNotificationEmail,
  type JobNotificationSms,
} from '@dropp/contrats';

import type { CanalVerification } from '../../../generated/prisma/enums.js';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @InjectQueue(QUEUE_NOTIFICATION)
    private readonly queue: Queue,
  ) {}

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
        await this.queue.add(JOB_NOTIFICATION.EMAIL, {
          destinataire: destination,
          sujet: 'Votre code DROPP',
          corps: messages[type],
        } satisfies JobNotificationEmail);
      } else {
        await this.queue.add(JOB_NOTIFICATION.SMS, {
          numero: destination,
          message: messages[type],
        } satisfies JobNotificationSms);
      }
    } catch (erreur) {
      this.logger.error(
        `Échec ajout job [${canal}] → ${destination} : ${String(erreur)}`,
      );
    }
  }
}
