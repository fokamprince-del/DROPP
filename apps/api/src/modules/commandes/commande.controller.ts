import { Controller, Get, Param, ParseUUIDPipe, Post } from '@nestjs/common';
import { Client } from '../auth/decorators/profils.decorator.js';
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
  lister(@CurrentUser() utilisateur: UtilisateurConnecte) {
    return this.commandes.lister(utilisateur.id);
  }

  @Client()
  @Get(':id')
  obtenir(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.commandes.obtenir(utilisateur.id, id);
  }
}
