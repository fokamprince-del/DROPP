import { MiddlewareConsumer, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { validationSchema } from './configuration/validation.js';
import configuration from './configuration/configuration.js';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { AuthentificationModule } from './modules/auth/auth.module.js';
import { LoggerHttpMiddleware } from './infrastructure/http/logger-http.middelware.js';
import { UsersModule } from './modules/users/users.module.js';
import { ClientsModule } from './modules/clients/clients.module.js';
import { SellersModule } from './modules/sellers/sellers.module.js';
import { ShopsModule } from './modules/shops/shops.module.js';
import { CategoriesModule } from './modules/categories/categories.module.js';
import { AuthentificationGuard } from './modules/auth/guards/auth.guard.js';

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
    UsersModule,
    ClientsModule,
    SellersModule,
    ShopsModule,
    CategoriesModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: AuthentificationGuard,
    },
  ],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerHttpMiddleware).forRoutes('*');
  }
}
