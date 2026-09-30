import { Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Redis } from 'ioredis';

import { REDIS_CLIENT } from '../redis/redis.provider.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from './stockage-provider.contract.js';
import { StockageProviderR2 } from './stockage-provider.r2.js';
import { StockageProviderStub } from './stockage-provider.stub.js';
import { StockageSuivi } from './stockage-suivi.js';

/** STOCKAGE_DRIVER=r2 → Cloudflare R2, sinon stub (dev). */
@Module({
  providers: [
    {
      provide: STOCKAGE_PROVIDER,
      inject: [ConfigService, REDIS_CLIENT],
      useFactory: (config: ConfigService, redis: Redis): StockageProvider => {
        const driver = config.get<string>('stockage.driver', 'stub');
        if (driver === 'r2') {
          return new StockageSuivi(new StockageProviderR2(config), redis);
        }

        if (config.get<string>('app.environment') === 'production') {
          throw new Error('STOCKAGE_DRIVER=stub interdit en production.');
        }
        new Logger('StockageModule').warn(
          'Stockage STUB actif : aucun fichier n’est réellement stocké.',
        );
        return new StockageProviderStub();
      },
    },
  ],
  exports: [STOCKAGE_PROVIDER],
})
export class StockageModule {}
