import { Body, Controller, Get, HttpCode, HttpStatus, Patch, Post } from '@nestjs/common';

import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { MiseAJourVendeurDto } from './dto/mise-a-jour-vendeur.dto.js';
import { SellersService } from './sellers.service.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { RequiertTelephoneVerifie } from '../auth/decorators/require-telephone-verifie.decorator.js';
import { RequiertIdempotenceKey } from '../../infrastructure/idempotence/idempotence.decorator.js';

/**
 * Pas de @Vendeur() ici : ce guard exige un vendeur ACTIF (KYC validé).
 * Or on devient vendeur via /devenir (statut EN_ATTENTE_VALIDATION), et un
 * vendeur en attente doit pouvoir consulter et compléter son profil.
 * Le service renvoie 404 si l'utilisateur n'a pas de profil vendeur.
 */
@Controller('sellers')
@RequiertTelephoneVerifie()
export class SellersController {
  constructor(private readonly sellersService: SellersService) {}

  @RequiertIdempotenceKey()
  @Post('devenir')
  @HttpCode(HttpStatus.NO_CONTENT)
  devenirVendeur(@CurrentUser() u: UtilisateurConnecte) {
    return this.sellersService.devenirVendeur(u.id);
  }

  @Get('me')
  obtenirProfil(@CurrentUser() u: UtilisateurConnecte) {
    return this.sellersService.obtenirProfil(u.id);
  }

  @Patch('me')
  mettreAJourProfil(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: MiseAJourVendeurDto,
  ) {
    return this.sellersService.mettreAJourProfil(u.id, dto);
  }
}
