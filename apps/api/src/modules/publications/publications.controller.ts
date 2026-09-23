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

import { Admin, Vendeur } from '../auth/decorators/profils.decorator.js';
import { Public } from '../auth/decorators/public.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { ConfirmerMediaPublicationDto } from './dto/confirmer-media-publication.dto.js';
import { CreerPublicationDto } from './dto/creer-publication.dto.js';
import { DemanderSignaturePublicationDto } from './dto/demander-signature-publication.dto.js';
import { MiseAJourPublicationDto } from './dto/mise-a-jour-publication.dto.js';
import { ModerationPublicationDto } from './dto/moderation-publication.dto.js';
import { PublicationsService } from './publications.service.js';

@Controller()
export class PublicationsController {
  constructor(private readonly publicationsService: PublicationsService) {}

  @Public()
  @Get('publications')
  listerPubliques(
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.publicationsService.listerPubliques(
      page,
      Math.min(limite, 100),
    );
  }

  @Public()
  @Get('publications/:id')
  obtenirPublique(@Param('id', ParseUUIDPipe) id: string) {
    return this.publicationsService.obtenirPublique(id);
  }

  @Vendeur()
  @Get('boutique/publications')
  listerMesPublications(@CurrentUser() utilisateur: UtilisateurConnecte) {
    return this.publicationsService.listerMesPublications(utilisateur.id);
  }

  @Vendeur()
  @Post('boutique/publications')
  creer(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Body() dto: CreerPublicationDto,
  ) {
    return this.publicationsService.creer(utilisateur.id, dto);
  }

  @Vendeur()
  @Patch('boutique/publications/:id')
  mettreAJour(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: MiseAJourPublicationDto,
  ) {
    return this.publicationsService.mettreAJour(utilisateur.id, id, dto);
  }

  @Vendeur()
  @Delete('boutique/publications/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async supprimer(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    await this.publicationsService.supprimer(utilisateur.id, id);
  }

  @Vendeur()
  @Post('boutique/publications/:id/media/signature')
  demanderSignature(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: DemanderSignaturePublicationDto,
  ) {
    return this.publicationsService.demanderSignature(utilisateur.id, id, dto);
  }

  @Vendeur()
  @Post('boutique/publications/:id/media')
  confirmerMedia(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ConfirmerMediaPublicationDto,
  ) {
    return this.publicationsService.confirmerMedia(utilisateur.id, id, dto);
  }

  @Admin('ADMIN')
  @Patch('admin/publications/:id/statut')
  moderer(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ModerationPublicationDto,
  ) {
    return this.publicationsService.moderer(id, dto.statut);
  }
}
