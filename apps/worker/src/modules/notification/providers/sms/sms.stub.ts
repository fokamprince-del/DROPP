import { Injectable, Logger } from '@nestjs/common';
import type { SmsProvider } from './sms.contract.js';

/** Développement uniquement : le SMS (code OTP compris) est écrit dans les logs. */
@Injectable()
export class SmsProviderStub implements SmsProvider {
  private readonly logger = new Logger(SmsProviderStub.name);

  async envoyer(numero: string, message: string): Promise<void> {
    this.logger.log(`[SMS STUB] → ${numero} : "${message}"`);
  }
}
