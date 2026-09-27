import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { Client } from '../auth/decorators/profils.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { AjouterArticlePanierDto } from './dto/ajouter-article-panier.dto.js';
import { ModifierArticlePanierDto } from './dto/modifier-article-panier.dto.js';
import { PanierService } from './panier.service.js';
import { RequiertIdempotenceKey } from '../../infrastructure/idempotence/idempotence.decorator.js';

@Controller('panier')
export class PanierController {
  constructor(private readonly panier: PanierService) {}

  @Client()
  @Get()
  obtenir(@CurrentUser() utilisateur: UtilisateurConnecte) {
    return this.panier.obtenir(utilisateur.id);
  }

  @RequiertIdempotenceKey()
  @Client()
  @Post('articles')
  ajouter(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Body() dto: AjouterArticlePanierDto,
  ) {
    return this.panier.ajouter(utilisateur.id, dto);
  }

  @Client()
  @Patch('articles/:id')
  modifier(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ModifierArticlePanierDto,
  ) {
    return this.panier.modifier(utilisateur.id, id, dto.quantite);
  }

  @Client()
  @Delete('articles/:id')
  supprimer(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.panier.supprimer(utilisateur.id, id);
  }
}
