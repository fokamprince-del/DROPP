import { Body, Controller, Get, Patch, Post, Req, UseGuards } from '@nestjs/common';
import type { Request } from 'express';

import { AuthentificationGuard } from '../auth/guards/auth.guard.js';
import type { UtilisateurAuthentifie } from '../auth/types/user-authentified.type.js';
import { EnregistrerBoutiqueDto } from './dto/enregistrer-boutique.dto.js';
import { MiseAJourBoutiqueDto } from './dto/mise-a-jour-boutique.dto.js';
import { ShopsService } from './shops.service.js';

type RequeteAuthentifiee = Request & { user: UtilisateurAuthentifie };

@Controller('shops')
@UseGuards(AuthentificationGuard)
export class ShopsController {
  constructor(private readonly shopsService: ShopsService) {}

  @Get('me')
  obtenirMaBoutique(@Req() requete: RequeteAuthentifiee) {
    return this.shopsService.obtenirMaBoutique(requete.user.utilisateurId);
  }

  @Post()
  creerBoutique(
    @Req() requete: RequeteAuthentifiee,
    @Body() dto: EnregistrerBoutiqueDto,
  ) {
    return this.shopsService.creerBoutique(requete.user.utilisateurId, dto);
  }

  @Patch('me')
  mettreAJourMaBoutique(
    @Req() requete: RequeteAuthentifiee,
    @Body() dto: MiseAJourBoutiqueDto,
  ) {
    return this.shopsService.mettreAJourMaBoutique(
      requete.user.utilisateurId,
      dto,
    );
  }
}
