import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule, type JwtModuleOptions } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';

import { AuthentificationController } from './auth.controller.js';
import { RoleAdminGuard } from './guards/admin.guard.js';
import { ProfilClientGuard } from './guards/client.guard.js';
import { RolesGuard } from './guards/roles.guard.js';
import { ProfilVendeurGuard } from './guards/vendeur.guard.js';

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
import { RenvoiCodeService } from './use-cases/renvoie-code.service.js';
import { ProfilMeService } from './use-cases/profil-me.service.js';
import { QueueModule } from '../../infrastructure/queue/queue.module.js';
import { StockageModule } from '../../infrastructure/stockage/stockage.module.js';
import { ChangementTelephoneService } from './use-cases/changement-telephone.service.js';
import { SuppressionCompteService } from './use-cases/suppression-compte.service.js';
import { VerificationEmailService } from './use-cases/verification-email.service.js';
import { ChangementMotDePasseService } from './use-cases/changement-mot-de-passe.service.js';

@Module({
  imports: [
    PrismaModule,
    QueueModule,
    StockageModule,
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
    ProfilMeService,
    ChangementTelephoneService,
    SuppressionCompteService,
    VerificationEmailService,
    ChangementMotDePasseService,

    // Stratégie Passport
    JwtStrategy,
    RolesGuard,
    RoleAdminGuard,
    ProfilClientGuard,
    ProfilVendeurGuard,
  ],
  exports: [RolesGuard, RoleAdminGuard, ProfilClientGuard, ProfilVendeurGuard, NotificationService],
})
export class AuthentificationModule {}
