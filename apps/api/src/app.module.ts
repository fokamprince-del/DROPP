import { MiddlewareConsumer, Module } from '@nestjs/common';
import { validationSchema } from './configuration/validation.js';
import configuration from './configuration/configuration.js';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { AuthentificationModule } from './modules/auth/auth.module.js';
import { LoggerHttpMiddleware } from './infrastructure/http/logger-http.middelware.js';

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
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerHttpMiddleware).forRoutes('*');
  }
}
