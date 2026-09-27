import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Ip,
  Param,
  Post,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';

import { Public } from './decorators/public.decorator.js';
import { CurrentUser } from './decorators/current-user.decorator.js';
import type { UtilisateurConnecte } from './types/utilisateur-connecte.js';

import { InscriptionDto } from './dto/inscription.dto.js';
import { VerifierOtpDto } from './dto/verifier-otp.dto.js';
import { ConnexionDto } from './dto/connexion.dto.js';
import { RefreshTokenDto } from './dto/refresh-token.dto.js';
import { MotDePasseOublieDto } from './dto/mot-de-passe-oublie.dto.js';
import { ReinitialisationMdpDto } from './dto/reinitialisation-mdp.dto.js';

import { InscriptionService } from './use-cases/inscription.service.js';
import { VerificationTelephoneService } from './use-cases/verification-telephone.service.js';
import { ConnexionService } from './use-cases/connexion.service.js';
import { RefreshTokenService } from './use-cases/refresh-token.service.js';
import { DeconnexionService } from './use-cases/deconnexion.service.js';
import { MotDePasseOublieService } from './use-cases/mot-de-passe-oublie.service.js';
import { ReinitialisationMdpService } from './use-cases/reinitialisation-mdp.service.js';
import { SessionsService } from './use-cases/sessions.service.js';
import { RenvoiCodeService } from './use-cases/renvoie-code.service.js';
import { RenvoiCodeDto } from './dto/renvoi-code.dto.js';
import { ProfilMeService } from './use-cases/profil-me.service.js';
import { RequiertIdempotenceKey } from '../../infrastructure/idempotence/idempotence.decorator.js';

/** Throttle nommé "court" : aligné sur la config ThrottlerModule de AppModule. */
const THROTTLE_SENSIBLE = { court: { limit: 5, ttl: 60_000 } };
const THROTTLE_STANDARD = { court: { limit: 10, ttl: 60_000 } };

@Controller('auth')
export class AuthentificationController {
  constructor(
    private readonly inscriptionService: InscriptionService,
    private readonly verificationTelephoneService: VerificationTelephoneService,
    private readonly renvoiCodeService: RenvoiCodeService,
    private readonly connexionService: ConnexionService,
    private readonly refreshTokenService: RefreshTokenService,
    private readonly deconnexionService: DeconnexionService,
    private readonly motDePasseOublieService: MotDePasseOublieService,
    private readonly reinitialisationMdpService: ReinitialisationMdpService,
    private readonly sessionsService: SessionsService,
    private readonly profilMeService: ProfilMeService,
  ) {}

  @Public()
  @Throttle(THROTTLE_STANDARD)
  @Post('inscription')
  @HttpCode(HttpStatus.CREATED)
  inscrire(@Body() dto: InscriptionDto) {
    return this.inscriptionService.executer(dto);
  }

  @Public()
  @Throttle(THROTTLE_SENSIBLE)
  @Post('verifier-telephone')
  @HttpCode(HttpStatus.OK)
  verifierTelephone(@Body() dto: VerifierOtpDto, @Ip() ip: string) {
    return this.verificationTelephoneService.executer(dto, ip);
  }

  @Public()
  @Throttle(THROTTLE_SENSIBLE)
  @Post('renvoyer-code')
  @HttpCode(HttpStatus.OK)
  renvoyerCode(@Body() dto: RenvoiCodeDto) {
    return this.renvoiCodeService.executer(dto);
  }

  @Public()
  @Throttle(THROTTLE_SENSIBLE)
  @Post('connexion')
  @HttpCode(HttpStatus.OK)
  connecter(@Body() dto: ConnexionDto, @Ip() ip: string) {
    return this.connexionService.executer(dto, ip);
  }

  @Public()
  @Throttle(THROTTLE_STANDARD)
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  rafraichir(@Body() dto: RefreshTokenDto) {
    return this.refreshTokenService.executer(dto.refreshToken);
  }

  @Post('deconnexion')
  @HttpCode(HttpStatus.NO_CONTENT)
  deconnecter(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Body('sessionId') sessionId: string,
  ) {
    return this.deconnexionService.executer(sessionId, utilisateur.id);
  }

  @Post('deconnecter-partout')
  @HttpCode(HttpStatus.NO_CONTENT)
  deconnecterPartout(@CurrentUser() utilisateur: UtilisateurConnecte) {
    return this.deconnexionService.deconnecterPartout(utilisateur.id);
  }

  @Get('sessions')
  listerSessions(@CurrentUser() utilisateur: UtilisateurConnecte) {
    return this.sessionsService.lister(utilisateur.id);
  }

  @Delete('sessions/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  revoquerSession(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id') sessionId: string,
  ) {
    return this.deconnexionService.executer(sessionId, utilisateur.id);
  }

  @Public()
  @Throttle(THROTTLE_SENSIBLE)
  @Post('mot-de-passe-oublie')
  @HttpCode(HttpStatus.NO_CONTENT)
  motDePasseOublie(@Body() dto: MotDePasseOublieDto) {
    return this.motDePasseOublieService.executer(dto);
  }

  @Public()
  @Throttle(THROTTLE_SENSIBLE)
  @RequiertIdempotenceKey()
  @Post('reinitialiser-mot-de-passe')
  @HttpCode(HttpStatus.OK)
  reinitialiserMotDePasse(
    @Body() dto: ReinitialisationMdpDto,
    @Ip() ip: string,
  ) {
    return this.reinitialisationMdpService.executer(dto, ip);
  }

  @Get('me')
  me(@CurrentUser() u: UtilisateurConnecte) {
    return this.profilMeService.executer(u.id);
  }
}
