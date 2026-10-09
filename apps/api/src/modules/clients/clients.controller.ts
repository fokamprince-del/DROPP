import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Req,
} from '@nestjs/common';
import type { Request } from 'express';

import { Client } from '../auth/decorators/profils.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { CreerAdresseDto } from './dto/creer-adresse.dto.js';
import { MiseAJourAdresseDto } from './dto/mise-a-jour-adresse.dto.js';
import { ClientsService } from './clients.service.js';

type RequeteAuthentifiee = Request & {
  user: UtilisateurConnecte;
};

@Controller('clients')
@Client()
export class ClientsController {
  constructor(private readonly clientsService: ClientsService) {}

  @Get('me')
  obtenirProfil(@Req() requete: RequeteAuthentifiee) {
    return this.clientsService.obtenirProfil(requete.user.id);
  }

  @Post('me/adresses')
  creerAdresse(
    @Req() requete: RequeteAuthentifiee,
    @Body() dto: CreerAdresseDto,
  ) {
    return this.clientsService.creerAdresse(requete.user.id, dto);
  }

  @Patch('me/adresses/:adresseId')
  mettreAJourAdresse(
    @Req() requete: RequeteAuthentifiee,
    @Param('adresseId', ParseUUIDPipe) adresseId: string,
    @Body() dto: MiseAJourAdresseDto,
  ) {
    return this.clientsService.mettreAJourAdresse(
      requete.user.id,
      adresseId,
      dto,
    );
  }

  @Delete('me/adresses/:adresseId')
  @HttpCode(204)
  async supprimerAdresse(
    @Req() requete: RequeteAuthentifiee,
    @Param('adresseId', ParseUUIDPipe) adresseId: string,
  ): Promise<void> {
    await this.clientsService.supprimerAdresse(requete.user.id, adresseId);
  }
}
