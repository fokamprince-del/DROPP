import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Redis } from 'ioredis';

export const REDIS_CLIENT = Symbol('REDIS_CLIENT');

export const RedisProvider = {
  provide: REDIS_CLIENT,
  inject: [ConfigService],
  useFactory: async (config: ConfigService): Promise<Redis> => {
    const logger = new Logger('RedisProvider');

    const client = new Redis({
      host: config.getOrThrow<string>('redis.host'),
      port: config.getOrThrow<number>('redis.port'),
      password: config.getOrThrow<string>('redis.password'),
      retryStrategy: (times: number) => {
        if (times > 10) {
          logger.error('Redis : trop de tentatives de reconnexion. Abandon.');
          return null;
        }
        const delai = Math.min(times * 200, 3000);
        logger.warn(`Redis : reconnexion dans ${delai}ms (tentative ${times})`);
        return delai;
      },
      // enableOfflineQueue à true (défaut) : les commandes attendent la connexion
      // lazyConnect à false : connexion immédiate au démarrage
      connectTimeout: 5000,
    });

    client.on('connect', () => logger.log('Redis connecté.'));
    client.on('error', (err: Error) =>
      logger.error(`Redis erreur : ${err.message}`),
    );

    // Connexion explicite au démarrage pour détecter les erreurs tôt
    await client.connect().catch((err: Error) => {
      logger.error(`Redis : échec de connexion initiale : ${err.message}`);
    });

    return client;
  },
};
