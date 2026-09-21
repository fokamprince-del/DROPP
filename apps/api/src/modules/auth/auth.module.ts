import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';

import { AuthentificationService } from './auth.service.js';
import { MotDePasseService } from './services/mot-de-passe.service.js';
import { OtpService } from './services/otp.service.js';
import { SessionService } from './services/session.service.js';
import { JwtStrategy } from './strategies/jwt.strategy.js';
import { SmsModule } from '../../infrastructure/sms/sms.module.js';
import { PassportModule } from '@nestjs/passport';
import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { AuthentificationController } from './auth.controller.js';
import { AuthentificationGuard } from './guards/auth.guard.js';
import { RolesGuard } from './guards/roles.guard.js';

@Module({
  imports: [
    PrismaModule,
    SmsModule,
    PassportModule.register({
      defaultStrategy: 'jwt',
    }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: configService.getOrThrow<string>('jwt.accessSecret'),
        signOptions: {
          expiresIn: configService.getOrThrow<string>('jwt.accessTtl') as any,
        },
      }),
    }),
  ],
  controllers: [AuthentificationController],
  providers: [
    AuthentificationService,
    MotDePasseService,
    OtpService,
    SessionService,
    JwtStrategy,
    AuthentificationGuard,
    RolesGuard,
  ],

  exports: [
    AuthentificationService,
    AuthentificationGuard,
    RolesGuard,
  ],
})
export class AuthentificationModule {}
