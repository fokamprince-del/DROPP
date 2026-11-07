import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Ip,
  Param,
  ParseUUIDPipe,
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
import { ChangementTelephoneService } from './use-cases/changement-telephone.service.js';
import { SuppressionCompteService } from './use-cases/suppression-compte.service.js';
import { VerificationEmailService } from './use-cases/verification-email.service.js';
import { ChangementMotDePasseService } from './use-cases/changement-mot-de-passe.service.js';
import {
  ChangerEmailDto,
  ChangerMotDePasseDto,
  VerifierEmailDto,
} from './dto/email.dto.js';
import {
  ConfirmerChangementTelephoneDto,
  DemanderChangementTelephoneDto,
  SupprimerCompteDto,
} from './dto/changement-telephone.dto.js';
import { RequiertIdempotenceKey } from '../../infrastructure/idempotence/idempotence.decorator.js';
import { ChangeEmailDto, ChangeTelephoneDto, ConnexionReponseDto, JetonsDto, ProfilMeDto, SessionDto, VerificationTokenDto } from './dto/auth-reponse.dto.js';
import { ApiCreatedResponse, ApiOkResponse } from '@nestjs/swagger';
import { ApiErreurs } from '../../infrastructure/http/api-erreur.decorator.js';

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
    private readonly changementTelephoneService: ChangementTelephoneService,
    private readonly suppressionCompteService: SuppressionCompteService,
    private readonly verificationEmailService: VerificationEmailService,
    private readonly changementMotDePasseService: ChangementMotDePasseService,
  ) {}

  @Public()
  @Throttle(THROTTLE_STANDARD)
  @Post('inscription')
  @HttpCode(HttpStatus.CREATED)
  @ApiCreatedResponse({ type: VerificationTokenDto })
  @ApiErreurs(409) // numéro ou e-mail déjà utilisé
  inscrire(@Body() dto: InscriptionDto): Promise<VerificationTokenDto> {
    return this.inscriptionService.executer(dto);
  }

  @Public()
  @Throttle(THROTTLE_SENSIBLE)
  @Post('verifier-telephone')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: JetonsDto })
  @ApiErreurs(401, 403, 410)
  verifierTelephone(@Body() dto: VerifierOtpDto, @Ip() ip: string) {
    return this.verificationTelephoneService.executer(dto, ip);
  }

  @Public()
  @Throttle(THROTTLE_SENSIBLE)
  @Post('renvoyer-code')
  @HttpCode(HttpStatus.OK)
  @ApiErreurs(401)
  renvoyerCode(@Body() dto: RenvoiCodeDto): Promise<VerificationTokenDto> {
    return this.renvoiCodeService.executer(dto);
  }

  @Public()
  @Throttle(THROTTLE_SENSIBLE)
  @Post('connexion')
  @HttpCode(HttpStatus.OK)
  @ApiErreurs(401, 403)
  connecter(@Body() dto: ConnexionDto, @Ip() ip: string): Promise<ConnexionReponseDto> {
    return this.connexionService.executer(dto, ip);
  }

  @Public()
  @Throttle(THROTTLE_STANDARD)
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiErreurs(401)
  rafraichir(@Body() dto: RefreshTokenDto): Promise<JetonsDto> {
    return this.refreshTokenService.executer(dto.refreshToken);
  }

  /** Ferme la session de cet appareil (celle qui a émis le jeton d'accès). */
  @Post('deconnexion')
  @HttpCode(HttpStatus.NO_CONTENT)
  deconnecter(@CurrentUser() utilisateur: UtilisateurConnecte) {
    return this.deconnexionService.executer(
      utilisateur.sessionId,
      utilisateur.id,
    );
  }

  @Post('deconnecter-partout')
  @HttpCode(HttpStatus.NO_CONTENT)
  deconnecterPartout(@CurrentUser() utilisateur: UtilisateurConnecte) {
    return this.deconnexionService.deconnecterPartout(utilisateur.id);
  }

  @Get('sessions')
  listerSessions(@CurrentUser() utilisateur: UtilisateurConnecte): Promise<SessionDto[]> {
    return this.sessionsService.lister(utilisateur.id, utilisateur.sessionId);
  }

  @Delete('sessions/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  revoquerSession(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) sessionId: string,
  ) {
    return this.deconnexionService.executer(sessionId, utilisateur.id);
  }

  /** Renvoie un verificationToken à joindre au code dans /reinitialiser-mot-de-passe. */
  @Public()
  @Throttle(THROTTLE_SENSIBLE)
  @Post('mot-de-passe-oublie')
  @HttpCode(HttpStatus.OK)
  motDePasseOublie(@Body() dto: MotDePasseOublieDto): Promise<VerificationTokenDto> {
    return this.motDePasseOublieService.executer(dto);
  }

  @Throttle(THROTTLE_SENSIBLE)
  @Post('mot-de-passe/changer')
  @HttpCode(HttpStatus.OK)
  @ApiErreurs(401, 410)
  changerMotDePasse(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: ChangerMotDePasseDto,
    @Ip() ip: string,
  ): Promise<JetonsDto> {
    return this.changementMotDePasseService.executer(u.id, dto, ip);
  }

  // ── Email ─────────────────────────────────────────────────────────────────

  /** (Re)envoie le code de confirmation à l'adresse actuelle. */
  @Throttle(THROTTLE_SENSIBLE)
  @Post('email/envoyer-code')
  @HttpCode(HttpStatus.OK)
  envoyerCodeEmail(@CurrentUser() u: UtilisateurConnecte): Promise<ChangeEmailDto> {
    return this.verificationEmailService.envoyerCode(u.id);
  }

  /** Nouvelle adresse : enregistrée seulement après /email/verifier. */
  @Throttle(THROTTLE_SENSIBLE)
  @Post('email/changer')
  @HttpCode(HttpStatus.OK)
  changerEmail(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: ChangerEmailDto,
  ): Promise<ChangeEmailDto> {
    return this.verificationEmailService.changer(u.id, dto);
  }

  @Throttle(THROTTLE_SENSIBLE)
  @RequiertIdempotenceKey()
  @Post('email/verifier')
  @HttpCode(HttpStatus.OK)
  verifierEmail(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: VerifierEmailDto,
  ) {
    return this.verificationEmailService.verifier(u.id, dto);
  }

  @Public()
  @Throttle(THROTTLE_SENSIBLE)
  @RequiertIdempotenceKey()
  @Post('reinitialiser-mot-de-passe')
  @HttpCode(HttpStatus.OK)
  reinitialiserMotDePasse(
    @Body() dto: ReinitialisationMdpDto,
    @Ip() ip: string,
  ): Promise<JetonsDto> {
    return this.reinitialisationMdpService.executer(dto, ip);
  }

  @Get('me')
  me(@CurrentUser() u: UtilisateurConnecte): Promise<ProfilMeDto> {
    return this.profilMeService.executer(u.id);
  }

  // ── Changement de numéro ──────────────────────────────────────────────────

  @Throttle(THROTTLE_SENSIBLE)
  @Post('telephone/changer')
  @HttpCode(HttpStatus.OK)
  demanderChangementTelephone(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: DemanderChangementTelephoneDto,
  ): Promise<ChangeTelephoneDto> {
    return this.changementTelephoneService.demander(u.id, dto);
  }

  @Throttle(THROTTLE_SENSIBLE)
  @Post('telephone/confirmer')
  @HttpCode(HttpStatus.OK)
  confirmerChangementTelephone(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: ConfirmerChangementTelephoneDto,
    @Ip() ip: string,
  ): Promise<{telephone: string}> {
    return this.changementTelephoneService.confirmer(u.id, dto, ip);
  }

  // ── Suppression de compte ─────────────────────────────────────────────────

  /** POST plutôt que DELETE : certains clients HTTP n'envoient pas de body sur DELETE. */
  @Throttle(THROTTLE_SENSIBLE)
  @Post('compte/supprimer')
  @HttpCode(HttpStatus.NO_CONTENT)
  supprimerCompte(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: SupprimerCompteDto,
    @Ip() ip: string,
  ) {
    return this.suppressionCompteService.executer(u.id, dto, ip);
  }
}
