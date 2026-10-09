import { Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { SMS_PROVIDER } from './sms.contract.js';
import { SmsProviderStub } from './sms.stub.js';
import { SmsProviderTwilio } from './sms.twilio.js';

/**
 * SMS_DRIVER=twilio → envoi réel ; stub sinon (codes affichés dans les logs).
 * Le stub est interdit en production : sans SMS, personne ne peut s'inscrire.
 */
@Module({
  providers: [
    {
      provide: SMS_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        if (config.get<string>('sms.driver') === 'twilio') {
          return new SmsProviderTwilio(config);
        }
        if (config.get<string>('app.environement') === 'production') {
          throw new Error('SMS_DRIVER=stub interdit en production.');
        }
        new Logger('SmsModule').warn('SMS simulés (stub) : les codes sont dans les logs.');
        return new SmsProviderStub();
      },
    },
  ],
  exports: [SMS_PROVIDER],
})
export class SmsModule {}
