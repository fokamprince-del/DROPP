import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UnrecoverableError } from 'bullmq';

import type { SmsProvider } from './sms.contract.js';

/**
 * Envoi via l'API REST de Twilio (https://www.twilio.com/docs/sms/api).
 * - 2xx : envoyé ;
 * - 429 / 5xx / réseau : erreur normale → BullMQ réessaie (backoff exponentiel) ;
 * - autre 4xx (identifiants, numéro invalide ou non joignable) :
 *   UnrecoverableError → pas de nouvelle tentative inutile.
 */
@Injectable()
export class SmsProviderTwilio implements SmsProvider {
  private readonly logger = new Logger(SmsProviderTwilio.name);
  private readonly url: string;
  private readonly autorisation: string;
  private readonly expediteur: string;

  constructor(config: ConfigService) {
    const compte = config.getOrThrow<string>('sms.twilio.accountSid');
    const jeton = config.getOrThrow<string>('sms.twilio.authToken');
    this.expediteur = config.getOrThrow<string>('sms.twilio.expediteur');
    this.url = `https://api.twilio.com/2010-04-01/Accounts/${compte}/Messages.json`;
    this.autorisation = `Basic ${Buffer.from(`${compte}:${jeton}`).toString('base64')}`;
  }

  async envoyer(numero: string, message: string): Promise<void> {
    const reponse = await fetch(this.url, {
      method: 'POST',
      headers: {
        Authorization: this.autorisation,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({ To: numero, From: this.expediteur, Body: message }),
      signal: AbortSignal.timeout(15_000),
    });

    if (reponse.ok) return;

    const detail = await reponse.text().catch(() => '');
    const erreur = `Twilio ${reponse.status} : ${detail.slice(0, 300)}`;
    if (reponse.status === 429 || reponse.status >= 500) {
      throw new Error(erreur);
    }
    this.logger.error(erreur);
    throw new UnrecoverableError(erreur);
  }
}
