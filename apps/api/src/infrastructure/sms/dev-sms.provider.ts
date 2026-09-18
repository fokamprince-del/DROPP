import {
  Injectable,
  Logger,
} from '@nestjs/common';

import {
  SmsProvider,
} from './sms-provider.js';

@Injectable()
export class DevelopmentSmsProvider
  implements SmsProvider {
  private readonly logger =
    new Logger(
      DevelopmentSmsProvider.name,
    );

  async envoyerCodeVerification(
    numeroTelephone: string,
    code: string,
  ): Promise<void> {
    this.logger.log(
      `[DEV SMS] Code envoyé à ${numeroTelephone}: ${code}`,
    );
  }
}