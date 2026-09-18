import {
  Module,
} from '@nestjs/common';

import {
  SMS_PROVIDER,
} from './sms-provider.js';

import {
  DevelopmentSmsProvider,
} from './dev-sms.provider.js';

@Module({
  providers: [
    DevelopmentSmsProvider,

    {
      provide: SMS_PROVIDER,

      useExisting:
        DevelopmentSmsProvider,
    },
  ],

  exports: [
    SMS_PROVIDER,
  ],
})
export class SmsModule {}