import { MiddlewareConsumer, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
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
import { LikesModule } from './modules/likes/likes.module.js';
import { InteractionsModule } from './modules/interactions/interactions.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      envFilePath: '.env',
      load: [configuration],
      validationSchema,
    }),

    ThrottlerModule.forRoot([
      {
        name: 'court',
        ttl: 60_000,
        limit: 20,
      },
    ]),
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
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: TelephoneVerifieGuard },
  ],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerHttpMiddleware).forRoutes('*');
  }
}
