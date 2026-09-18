import { Module } from '@nestjs/common';
import { validationSchema } from './configuration/validation.js';
import configuration from './configuration/configuration.js';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './infrastructure/database/prisma.module.js';
import { ThrottlerModule } from '@nestjs/throttler';
import { AuthentificationModule } from './modules/auth/auth.module.js';

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
export class AppModule {}
