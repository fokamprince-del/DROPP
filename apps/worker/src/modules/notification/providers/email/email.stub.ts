import { Injectable, Logger } from '@nestjs/common';
import type { EmailProvider } from './email.contract.js';

@Injectable()
export class EmailProviderStub implements EmailProvider {
  private readonly logger = new Logger(EmailProviderStub.name);

  async envoyer(
    destinataire: string,
    sujet: string,
    corps: string,
  ): Promise<void> {
    this.logger.debug(`[EMAIL STUB] → ${destinataire} | ${sujet} : "${corps}"`);
  }
}
