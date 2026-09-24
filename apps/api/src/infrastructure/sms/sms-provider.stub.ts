import { Injectable, Logger } from '@nestjs/common';
import type { SmsProvider } from './sms-provider.contract.js';

@Injectable()
export class SmsProviderStub implements SmsProvider {
  private readonly logger = new Logger(SmsProviderStub.name);

  async envoyer(numero: string, message: string): Promise<void> {
    this.logger.debug(`[SMS STUB] → ${numero} : "${message}"`);
  }
}
