import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule, type JwtModuleOptions } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { SmsModule } from '../../infrastructure/sms/sms.module.js';

import { AuthentificationController } from './auth.controller.js';

import { JetonService } from './services/jeton.service.js';
import { MotDePasseService } from './services/mot-de-passe.service.js';
import { NotificationService } from './services/notification.service.js';
import { OtpService } from './services/otp.service.js';
import { SessionsService } from './use-cases/sessions.service.js';
import { TelephoneService } from './services/telephone.service.js';

import { ConnexionService } from './use-cases/connexion.service.js';
import { DeconnexionService } from './use-cases/deconnexion.service.js';
import { InscriptionService } from './use-cases/inscription.service.js';
import { MotDePasseOublieService } from './use-cases/mot-de-passe-oublie.service.js';
import { ReinitialisationMdpService } from './use-cases/reinitialisation-mdp.service.js';
import { RefreshTokenService } from './use-cases/refresh-token.service.js';
import { VerificationTelephoneService } from './use-cases/verification-telephone.service.js';

import { JwtStrategy } from './strategies/jwt.strategy.js';

// NotificationProvider : stub en dev, vrai fournisseur plus tard
import { NOTIFICATION_PROVIDER } from '../../infrastructure/notification/notification-provider.contract.js';
import { NotificationProviderStub } from '../../infrastructure/notification/notification-provider.stub.js';
import { RenvoiCodeService } from './use-cases/renvoie-code.service.js';

@Module({
  imports: [
    PrismaModule,
    SmsModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService): JwtModuleOptions => ({
        secret: config.getOrThrow<string>('jwt.accessSecret'),
        signOptions: {
          algorithm: 'HS256',
          expiresIn: config.getOrThrow<number>('auth.accessTokenTtlSeconds'),
        },
        verifyOptions: { algorithms: ['HS256'] },
      }),
    }),
  ],

  controllers: [AuthentificationController],

  providers: [
    // Services techniques
    JetonService,
    MotDePasseService,
    NotificationService,
    OtpService,
    TelephoneService,

    // Cas d'usage
    ConnexionService,
    DeconnexionService,
    InscriptionService,
    MotDePasseOublieService,
    ReinitialisationMdpService,
    RefreshTokenService,
    SessionsService,
    RenvoiCodeService,
    VerificationTelephoneService,

    // Stratégie Passport
    JwtStrategy,

    // NotificationProvider provisoire (stub SMS)
    // À remplacer par un vrai fournisseur ou un BullMQ producer
    {
      provide: NOTIFICATION_PROVIDER,
      useClass: NotificationProviderStub,
    },
  ],
})
export class AuthentificationModule {}