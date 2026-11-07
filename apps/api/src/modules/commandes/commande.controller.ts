import {
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseEnumPipe,
  ParseIntPipe,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';

import { StatutCommande } from '@dropp/database';
import { Client, Vendeur } from '../auth/decorators/profils.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { CommandeService } from './commande.service.js';
import { RequiertIdempotenceKey } from '../../infrastructure/idempotence/idempotence.decorator.js';

@Controller('commandes')
export class CommandeController {
  constructor(private readonly commandes: CommandeService) {}

  @RequiertIdempotenceKey()
  @Client()
  @Post()
  passer(@CurrentUser() utilisateur: UtilisateurConnecte) {
    return this.commandes.passer(utilisateur.id);
  }

  @Client()
  @Get()
  lister(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.commandes.lister(
      utilisateur.id,
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 50),
    );
  }

  @Client()
  @Get(':id')
  obtenir(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.commandes.obtenir(utilisateur.id, id);
  }

  @Client()
  @Post(':id/annuler')
  @HttpCode(HttpStatus.OK)
  annuler(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.commandes.annuler(utilisateur.id, id);
  }
}

/**
 * Commandes reçues par le vendeur (une sous-commande par boutique).
 * Lecture seule : l'expédition et la livraison arriveront avec leur module.
 */
@Controller('boutique/commandes')
export class VentesController {
  constructor(private readonly commandes: CommandeService) {}

  @Vendeur()
  @Get()
  lister(
    @CurrentUser() u: UtilisateurConnecte,
    @Query('statut', new ParseEnumPipe(StatutCommande, { optional: true }))
    statut?: StatutCommande,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.commandes.listerVentes(
      u.id,
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 50),
      statut,
    );
  }

  @Vendeur()
  @Get(':id')
  obtenir(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.commandes.obtenirVente(u.id, id);
  }
}
