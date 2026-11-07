import { Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PUSH_PROVIDER } from './push.contract.js';
import { PushProviderFcm } from './push.fcm.js';
import { PushProviderStub } from './push.stub.js';

/**
 * FCM si les identifiants Firebase sont renseignés, sinon stub (push
 * seulement loggés). Autorisé en production (l'app peut sortir avant les
 * push), mais signalé au démarrage pour ne pas passer inaperçu.
 */
@Module({
  providers: [
    {
      provide: PUSH_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        if (config.get<string>('firebase.projectId')) {
          return new PushProviderFcm(config);
        }
        const logger = new Logger('PushModule');
        if (config.get<string>('app.environment') === 'production') {
          logger.error(
            'FIREBASE_* absents en production : AUCUNE notification push ne sera envoyée.',
          );
        } else {
          logger.warn('FIREBASE_* absents : notifications push simulées (stub).');
        }
        return new PushProviderStub();
      },
    },
  ],
  exports: [PUSH_PROVIDER],
})
export class PushModule {}
