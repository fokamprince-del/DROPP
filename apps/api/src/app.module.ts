import { MiddlewareConsumer, Module } from '@nestjs/common';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { validationSchema } from './configuration/validation.js';
import configuration from './configuration/configuration.js';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuthentificationModule } from './modules/auth/auth.module.js';
import { LoggerHttpMiddleware } from './infrastructure/http/logger-http.middelware.js';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard.js';
import { TelephoneVerifieGuard } from './modules/auth/guards/telephone-verifier.guard.js';
import { ProduitsModule } from './modules/produits/produits.module.js';
import { UsersModule } from './modules/users/users.module.js';
import { ClientsModule } from './modules/clients/clients.module.js';
import { SellersModule } from './modules/sellers/sellers.module.js';
import { ShopsModule } from './modules/shops/shops.module.js';
import { CategoriesModule } from './modules/categories/categories.module.js';
import { PublicationsModule } from './modules/publications/publications.module.js';
import { StoriesModule } from './modules/stories/stories.module.js';
import { InteractionsModule } from './modules/interactions/interactions.module.js';
import { PanierModule } from './modules/panier/panier.module.js';
import { CommandesModule } from './modules/commandes/commandes.module.js';
import { RedisModule } from './infrastructure/redis/redis.module.js';
import { REDIS_CLIENT } from './infrastructure/redis/redis.provider.js';
import { RevocationModule } from './infrastructure/revocation/revocation.module.js';
import { SanteModule } from './infrastructure/sante/sante.module.js';
import { ThrottlerStorageRedis } from './infrastructure/throttler/throttler-storage.redis.js';
import type { Redis } from 'ioredis';
import { IdempotenceModule } from './infrastructure/idempotence/idempotence.module.js';
import { IdempotenceInterceptor } from './infrastructure/idempotence/idempotence.interceptor.js';
import { QueueModule } from './infrastructure/queue/queue.module.js';
import { RealtimeModule } from './infrastructure/realtime/realtime.module.js';
import { MaintenanceModule } from './infrastructure/maintenance/maintenance.module.js';
import { NotificationsModule } from './modules/notifications/notifications.module.js';
import { MessagerieModule } from './modules/messagerie/messagerie.module.js';
import { SignalementsModule } from './modules/signalements/signalements.module.js';
import { AvisModule } from './modules/avis/avis.module.js';
import { KycModule } from './modules/kyc/kyc.module.js';
import { AdminModule } from './modules/admin/admin.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      envFilePath: '.env',
      load: [configuration],
      validationSchema,
    }),
    RedisModule,
    ThrottlerModule.forRootAsync({
      inject: [REDIS_CLIENT],
      useFactory: (redis: Redis) => ({
        throttlers: [
          {
            name: 'court',
            ttl: 60_000,
            limit: 20,
          },
        ],
        // Compteurs partagés entre toutes les instances de l'API.
        storage: new ThrottlerStorageRedis(redis),
        // Tests automatisés (NODE_ENV=test) : rafales de requêtes depuis une IP.
        skipIf: () => process.env.NODE_ENV === 'test',
      }),
    }),
    RevocationModule,
    SanteModule,
    IdempotenceModule,
    QueueModule,
    RealtimeModule,
    MaintenanceModule,
    NotificationsModule,
    AuthentificationModule,
    ProduitsModule,
    UsersModule,
    ClientsModule,
    SellersModule,
    ShopsModule,
    CategoriesModule,
    PublicationsModule,
    StoriesModule,
    InteractionsModule,
    PanierModule,
    CommandesModule,
    MessagerieModule,
    SignalementsModule,
    AvisModule,
    KycModule,
    AdminModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: TelephoneVerifieGuard },
    { provide: APP_INTERCEPTOR, useClass: IdempotenceInterceptor },
  ],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerHttpMiddleware).forRoutes('*');
  }
}
