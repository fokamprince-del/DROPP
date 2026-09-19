import { Body, Controller, Ip, Param, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';

import { AuthentificationService } from './auth.service.js';

import { Public } from './decorators/public.decorator.js';

import { ConnexionDto } from './dto/connexion.dto.js';
import { DemandeReinitialisationDto } from './dto/demande-reinitialisation.dto.js';
import { InscriptionDto } from './dto/inscription.dto.js';
import { RenvoiCodeDto } from './dto/renvoi-code.dto.js';
import { RenouvellementTokenDto } from './dto/renouvellement-token.dto.js';
import { VerificationOtpDto } from './dto/verification-otp.dto.js';

@Controller('auth')
export class AuthentificationController {
  constructor(
    private readonly authentificationService: AuthentificationService,
  ) {}

  @Public()
  @Post('inscription')
  async inscrire(@Body() dto: InscriptionDto, @Ip() adresseIp: string) {
    return this.authentificationService.inscrire(dto, adresseIp);
  }

  @Public()
  @Throttle({
    court: {
      ttl: 60_000,
      limit: 5,
    },
  })
  @Post('inscription/:utilisateurId/verification')
  async verifierInscription(
    @Param('utilisateurId')
    utilisateurId: string,

    @Body()
    dto: VerificationOtpDto,
  ) {
    return this.authentificationService.verifierInscription(utilisateurId, dto);
  }

  @Public()
  @Throttle({
    court: {
      ttl: 60_000,
      limit: 5,
    },
  })
  @Post('verification/renvoi')
  async renvoyerCode(
    @Body()
    dto: RenvoiCodeDto,
  ) {
    return this.authentificationService.renvoyerCode(dto);
  }

  @Public()
  @Throttle({
    court: {
      ttl: 60_000,
      limit: 5,
    },
  })
  @Post('connexion')
  async connecter(
    @Body()
    dto: ConnexionDto,

    @Ip()
    adresseIp: string,
  ) {
    return this.authentificationService.connecter(dto, adresseIp);
  }

  @Public()
  @Throttle({
    court: {
      ttl: 60_000,
      limit: 5,
    },
  })
  @Post('renouvellement')
  async renouveler(
    @Body()
    dto: RenouvellementTokenDto,
  ) {
    return this.authentificationService.renouveler(dto);
  }

  @Public()
  @Post('reinitialisation/demande')
  async demanderReinitialisation(
    @Body()
    _dto: DemandeReinitialisationDto,
  ) {
    /*
     * Fonctionnalité volontairement non implémentée
     * ici tant que le flux de réinitialisation complet
     * n'est pas verrouillé.
     */
    return {
      message:
        'Si un compte correspondant existe, une procédure de réinitialisation sera envoyée.',
    };
  }
}
