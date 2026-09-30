import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UnrecoverableError } from 'bullmq';

import type { EmailProvider } from './email.contract.js';

const URL_RESEND = 'https://api.resend.com/emails';

/**
 * Envoi via l'API HTTP de Resend (https://resend.com/docs/api-reference).
 * - 2xx : envoyé ;
 * - 429 / 5xx / réseau : erreur normale → BullMQ réessaie (backoff exponentiel) ;
 * - autre 4xx (clé invalide, domaine non vérifié, adresse invalide) :
 *   UnrecoverableError → pas de nouvelle tentative inutile.
 */
@Injectable()
export class EmailProviderResend implements EmailProvider {
  private readonly logger = new Logger(EmailProviderResend.name);
  private readonly cleApi: string;
  private readonly expediteur: string;
  private readonly repondreA?: string;

  constructor(config: ConfigService) {
    this.cleApi = config.getOrThrow<string>('email.resendApiKey');
    this.expediteur = config.getOrThrow<string>('email.expediteur');
    this.repondreA = config.get<string>('email.repondreA') || undefined;
  }

  async envoyer(
    destinataire: string,
    sujet: string,
    corps: string,
    html?: string,
  ): Promise<void> {
    const reponse = await fetch(URL_RESEND, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.cleApi}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: this.expediteur,
        to: [destinataire],
        subject: sujet,
        text: corps,
        ...(html && { html }),
        ...(this.repondreA && { reply_to: this.repondreA }),
      }),
      signal: AbortSignal.timeout(10_000),
    });

    if (reponse.ok) {
      const { id } = (await reponse.json()) as { id?: string };
      this.logger.log(`Email envoyé (${id ?? '?'}) → ${masquer(destinataire)}`);
      return;
    }

    const detail = await reponse.text().catch(() => '');
    const message = `Resend ${reponse.status} : ${detail.slice(0, 300)}`;
    if (reponse.status === 429 || reponse.status >= 500) {
      throw new Error(message);
    }
    this.logger.error(message);
    throw new UnrecoverableError(message);
  }
}

/** jean.dupont@mail.com → je***@mail.com (pas d'adresse complète dans les logs). */
function masquer(email: string): string {
  const [nom, domaine] = email.split('@');
  return `${nom.slice(0, 2)}***@${domaine ?? ''}`;
}
