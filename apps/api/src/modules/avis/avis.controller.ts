import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';

import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { Client } from '../auth/decorators/profils.decorator.js';
import { Public } from '../auth/decorators/public.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { AvisService } from './avis.service.js';
import { CreerAvisDto, ModifierAvisDto } from './dto/avis.dto.js';

@Controller()
export class AvisController {
  constructor(private readonly avis: AvisService) {}

  @Public()
  @Get('produits/:id/avis')
  listerPourProduit(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.avis.listerPourProduit(
      id,
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 50),
    );
  }

  @Public()
  @Get('boutiques/:id/avis/resume')
  resumeBoutique(@Param('id', ParseUUIDPipe) id: string) {
    return this.avis.resumeBoutique(id);
  }

  @Client()
  @Get('moi/avis/a-noter')
  aNoter(@CurrentUser() u: UtilisateurConnecte) {
    return this.avis.aNoter(u.id);
  }

  @Client()
  @Post('avis')
  creer(@CurrentUser() u: UtilisateurConnecte, @Body() dto: CreerAvisDto) {
    return this.avis.creer(u.id, dto);
  }

  @Client()
  @Patch('avis/:id')
  modifier(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ModifierAvisDto,
  ) {
    return this.avis.modifier(u.id, id, dto);
  }

  @Client()
  @Delete('avis/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  supprimer(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.avis.supprimer(u.id, id);
  }
}
