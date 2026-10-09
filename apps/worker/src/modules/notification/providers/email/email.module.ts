import { Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { EMAIL_PROVIDER } from './email.contract.js';
import { EmailProviderResend } from './email.resend.js';
import { EmailProviderStub } from './email.stub.js';

/** Resend si RESEND_API_KEY est renseignée, sinon stub (emails loggés, interdit en production). */
@Module({
  providers: [
    {
      provide: EMAIL_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        if (config.get<string>('email.resendApiKey')) {
          return new EmailProviderResend(config);
        }
        if (config.get<string>('app.environement') === 'production') {
          throw new Error('RESEND_API_KEY obligatoire en production.');
        }
        new Logger('EmailModule').warn(
          'RESEND_API_KEY absente : emails simulés (stub).',
        );
        return new EmailProviderStub();
      },
    },
  ],
  exports: [EMAIL_PROVIDER],
})
export class EmailModule {}
