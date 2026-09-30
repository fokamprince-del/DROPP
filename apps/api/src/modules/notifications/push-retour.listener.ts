import { Logger } from '@nestjs/common';
import {
  OnQueueEvent,
  QueueEventsHost,
  QueueEventsListener,
} from '@nestjs/bullmq';

import {
  QUEUE_NOTIFICATION,
  type ResultatNotificationPush,
} from '@dropp/contrats';

import { PrismaService } from '../../infrastructure/database/prisma.service.js';

/**
 * Le worker n'a pas accès à la base : il renvoie les jetons FCM morts comme
 * valeur de retour du job PUSH, et l'API les supprime ici.
 */
@QueueEventsListener(QUEUE_NOTIFICATION)
export class PushRetourListener extends QueueEventsHost {
  private readonly logger = new Logger(PushRetourListener.name);

  constructor(private readonly prisma: PrismaService) {
    super();
  }

  @OnQueueEvent('completed')
  async surJobTermine({ returnvalue }: { jobId: string; returnvalue: unknown }) {
    const resultat = this.lire(returnvalue);
    if (!resultat || resultat.tokensInvalides.length === 0) return;

    const { count } = await this.prisma.appareil.deleteMany({
      where: { tokenFcm: { in: resultat.tokensInvalides } },
    });
    this.logger.log(`${count} jeton(s) FCM expiré(s) supprimé(s).`);
  }

  private lire(valeur: unknown): ResultatNotificationPush | null {
    try {
      const objet: unknown =
        typeof valeur === 'string' ? JSON.parse(valeur) : valeur;
      if (
        objet &&
        typeof objet === 'object' &&
        Array.isArray((objet as ResultatNotificationPush).tokensInvalides)
      ) {
        return objet as ResultatNotificationPush;
      }
    } catch {
      // valeur de retour d'un autre type de job (SMS, email) : ignorée
    }
    return null;
  }
}
