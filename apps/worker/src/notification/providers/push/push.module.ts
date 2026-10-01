import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PUSH_PROVIDER } from './push.contract.js';
import { PushProviderFcm } from './push.fcm.js';
import { PushProviderStub } from './push.stub.js';

/** FCM si les identifiants Firebase sont renseignés, sinon stub (dev). */
@Module({
  providers: [
    {
      provide: PUSH_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        config.get<string>('firebase.projectId')
          ? new PushProviderFcm(config)
          : new PushProviderStub(),
    },
  ],
  exports: [PUSH_PROVIDER],
})
export class PushModule {}
