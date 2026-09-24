import { Injectable, Logger } from '@nestjs/common';
import type { NotificationProvider } from './notification-provider.contract.js';

@Injectable()
export class NotificationProviderStub implements NotificationProvider {
  private readonly logger = new Logger(NotificationProviderStub.name);

  async envoyerSms(numero: string, message: string): Promise<void> {
    this.logger.debug(`[SMS STUB] → ${numero} : "${message}"`);
  }

  async envoyerEmail(
    destinataire: string,
    sujet: string,
    corps: string,
  ): Promise<void> {
    this.logger.debug(`[EMAIL STUB] → ${destinataire} | ${sujet} : "${corps}"`);
  }
}
