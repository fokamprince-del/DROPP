import { Body, Controller, Get, Patch, Req } from '@nestjs/common';
import type { Request } from 'express';

import { Vendeur } from '../auth/decorators/profils.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { MiseAJourVendeurDto } from './dto/mise-a-jour-vendeur.dto.js';
import { SellersService } from './sellers.service.js';

type RequeteAuthentifiee = Request & { user: UtilisateurConnecte };

@Controller('sellers')
@Vendeur()
export class SellersController {
  constructor(private readonly sellersService: SellersService) {}

  @Get('me')
  obtenirProfil(@Req() requete: RequeteAuthentifiee) {
    return this.sellersService.obtenirProfil(requete.user.id);
  }

  @Patch('me')
  mettreAJourProfil(
    @Req() requete: RequeteAuthentifiee,
    @Body() dto: MiseAJourVendeurDto,
  ) {
    return this.sellersService.mettreAJourProfil(
      requete.user.id,
      dto,
    );
  }
}
