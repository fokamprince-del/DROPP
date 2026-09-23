import { Body, Controller, Get, Patch, Post, Req } from '@nestjs/common';
import type { Request } from 'express';

import { Vendeur } from '../auth/decorators/profils.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { EnregistrerBoutiqueDto } from './dto/enregistrer-boutique.dto.js';
import { MiseAJourBoutiqueDto } from './dto/mise-a-jour-boutique.dto.js';
import { ShopsService } from './shops.service.js';

type RequeteAuthentifiee = Request & { user: UtilisateurConnecte };

@Controller('shops')
@Vendeur()
export class ShopsController {
  constructor(private readonly shopsService: ShopsService) {}

  @Get('me')
  obtenirMaBoutique(@Req() requete: RequeteAuthentifiee) {
    return this.shopsService.obtenirMaBoutique(requete.user.id);
  }

  @Post()
  creerBoutique(
    @Req() requete: RequeteAuthentifiee,
    @Body() dto: EnregistrerBoutiqueDto,
  ) {
    return this.shopsService.creerBoutique(requete.user.id, dto);
  }

  @Patch('me')
  mettreAJourMaBoutique(
    @Req() requete: RequeteAuthentifiee,
    @Body() dto: MiseAJourBoutiqueDto,
  ) {
    return this.shopsService.mettreAJourMaBoutique(requete.user.id, dto);
  }
}
