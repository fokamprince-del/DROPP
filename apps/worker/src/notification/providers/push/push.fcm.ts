import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { cert, initializeApp, type App } from 'firebase-admin/app';
import { getMessaging, type Messaging } from 'firebase-admin/messaging';

import type { MessagePush, PushProvider } from './push.contract.js';

/** Codes FCM indiquant que le jeton ne sera plus jamais valide. */
const CODES_JETON_MORT = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/** FCM accepte au plus 500 jetons par envoi multicast. */
const TAILLE_LOT = 500;

@Injectable()
export class PushProviderFcm implements PushProvider {
  private readonly logger = new Logger(PushProviderFcm.name);
  private readonly messaging: Messaging;

  constructor(config: ConfigService) {
    const app: App = initializeApp({
      credential: cert({
        projectId: config.getOrThrow<string>('firebase.projectId'),
        clientEmail: config.getOrThrow<string>('firebase.clientEmail'),
        privateKey: config.getOrThrow<string>('firebase.privateKey'),
      }),
    });
    this.messaging = getMessaging(app);
  }

  async envoyer(message: MessagePush): Promise<{ tokensInvalides: string[] }> {
    const tokensInvalides: string[] = [];

    for (let i = 0; i < message.tokens.length; i += TAILLE_LOT) {
      const lot = message.tokens.slice(i, i + TAILLE_LOT);
      const reponse = await this.messaging.sendEachForMulticast({
        tokens: lot,
        notification: { title: message.titre, body: message.corps },
        data: message.donnees,
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });

      reponse.responses.forEach((r, index) => {
        if (!r.success && r.error && CODES_JETON_MORT.has(r.error.code)) {
          tokensInvalides.push(lot[index]);
        }
      });

      this.logger.log(
        `Push : ${reponse.successCount} ok, ${reponse.failureCount} échec(s).`,
      );
    }

    return { tokensInvalides };
  }
}
