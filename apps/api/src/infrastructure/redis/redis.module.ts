import { Global, Module, OnApplicationShutdown } from '@nestjs/common';
import { Inject } from '@nestjs/common';
import type { Redis } from 'ioredis';

import { REDIS_CLIENT, RedisProvider } from './redis.provider.js';

/**
 * Global : REDIS_CLIENT disponible dans tous les modules sans import explicite.
 * Fermeture propre de la connexion à l'arrêt de l'application.
 */
@Global()
@Module({
  providers: [RedisProvider],
  exports: [REDIS_CLIENT],
})
export class RedisModule implements OnApplicationShutdown {
  constructor(@Inject(REDIS_CLIENT) private readonly redis: Redis) {}

  async onApplicationShutdown(): Promise<void> {
    await this.redis.quit();
  }
}
