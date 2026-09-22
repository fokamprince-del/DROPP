import { MiddlewareConsumer, Module } from '@nestjs/common';
import { validationSchema } from './configuration/validation.js';
import configuration from './configuration/configuration.js';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuthentificationModule } from './modules/auth/auth.module.js';
import { LoggerHttpMiddleware } from './infrastructure/http/logger-http.middelware.js';
import { APP_GUARD } from '@nestjs/core';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard.js';
import { TelephoneVerifieGuard } from './modules/auth/guards/telephone-verifier.guard.js';

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
