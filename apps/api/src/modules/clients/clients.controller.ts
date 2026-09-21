import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';

import { AuthentificationGuard } from '../auth/guards/auth.guard.js';
import type { UtilisateurAuthentifie } from '../auth/types/user-authentified.type.js';
import { CreerAdresseDto } from './dto/creer-adresse.dto.js';
import { MiseAJourAdresseDto } from './dto/mise-a-jour-adresse.dto.js';
import { ClientsService } from './clients.service.js';

type RequeteAuthentifiee = Request & {
  user: UtilisateurAuthentifie;
};

@Controller('clients')
@UseGuards(AuthentificationGuard)
export class ClientsController {
  constructor(private readonly clientsService: ClientsService) {}

  @Get('me')
  obtenirProfil(@Req() requete: RequeteAuthentifiee) {
    return this.clientsService.obtenirProfil(requete.user.utilisateurId);
  }

  @Post('me/adresses')
  creerAdresse(
    @Req() requete: RequeteAuthentifiee,
    @Body() dto: CreerAdresseDto,
  ) {
    return this.clientsService.creerAdresse(requete.user.utilisateurId, dto);
  }

  @Patch('me/adresses/:adresseId')
  mettreAJourAdresse(
    @Req() requete: RequeteAuthentifiee,
    @Param('adresseId') adresseId: string,
    @Body() dto: MiseAJourAdresseDto,
  ) {
    return this.clientsService.mettreAJourAdresse(
      requete.user.utilisateurId,
      adresseId,
      dto,
    );
  }

  @Delete('me/adresses/:adresseId')
  @HttpCode(204)
  async supprimerAdresse(
    @Req() requete: RequeteAuthentifiee,
    @Param('adresseId') adresseId: string,
  ): Promise<void> {
    await this.clientsService.supprimerAdresse(
      requete.user.utilisateurId,
      adresseId,
    );
  }
}
