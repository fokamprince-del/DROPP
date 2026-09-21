import { Body, Controller, Get, Patch, Req, UseGuards } from '@nestjs/common';
import type { Request } from 'express';

import { AuthentificationGuard } from '../auth/guards/auth.guard.js';
import type { UtilisateurAuthentifie } from '../auth/types/user-authentified.type.js';
import { MiseAJourVendeurDto } from './dto/mise-a-jour-vendeur.dto.js';
import { SellersService } from './sellers.service.js';

type RequeteAuthentifiee = Request & { user: UtilisateurAuthentifie };

@Controller('sellers')
@UseGuards(AuthentificationGuard)
export class SellersController {
  constructor(private readonly sellersService: SellersService) {}

  @Get('me')
  obtenirProfil(@Req() requete: RequeteAuthentifiee) {
    return this.sellersService.obtenirProfil(requete.user.utilisateurId);
  }

  @Patch('me')
  mettreAJourProfil(
    @Req() requete: RequeteAuthentifiee,
    @Body() dto: MiseAJourVendeurDto,
  ) {
    return this.sellersService.mettreAJourProfil(
      requete.user.utilisateurId,
      dto,
    );
  }
}
