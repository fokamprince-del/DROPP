import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Ip,
  Param,
  ParseEnumPipe,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';

import { StatutPublication } from '@dropp/database';
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
import { RequiertIdempotenceKey } from '../../infrastructure/idempotence/idempotence.decorator.js';

@Controller()
export class PublicationsController {
  constructor(private readonly publicationsService: PublicationsService) {}

  @Public()
  @Get('publications')
  listerPubliques(
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
    @Query('boutiqueId', new ParseUUIDPipe({ optional: true }))
    boutiqueId?: string,
    @CurrentUser() utilisateur?: UtilisateurConnecte,
  ) {
    return this.publicationsService.listerPubliques(
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 100),
      boutiqueId,
      utilisateur?.id,
    );
  }

  /** À appeler quand la publication est réellement affichée à l'écran. */
  @Public()
  @Post('publications/:id/vue')
  @HttpCode(HttpStatus.OK)
  marquerVue(
    @Param('id', ParseUUIDPipe) id: string,
    @Ip() ip: string,
    @CurrentUser() utilisateur?: UtilisateurConnecte,
  ) {
    return this.publicationsService.marquerVue(
      id,
      utilisateur ? `u:${utilisateur.id}` : `ip:${ip}`,
    );
  }

  @Get('publications/fil/abonnements')
  filAbonnements(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.publicationsService.listerFilAbonnements(
      utilisateur.id,
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 100),
    );
  }

  @Public()
  @Get('publications/:id')
  obtenirPublique(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() utilisateur?: UtilisateurConnecte,
  ) {
    return this.publicationsService.obtenirPublique(id, utilisateur?.id);
  }

  @Vendeur()
  @Get('boutique/publications')
  listerMesPublications(@CurrentUser() utilisateur: UtilisateurConnecte) {
    return this.publicationsService.listerMesPublications(utilisateur.id);
  }

  @RequiertIdempotenceKey()
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

  @RequiertIdempotenceKey()
  @Vendeur()
  @Post('boutique/publications/:id/media')
  confirmerMedia(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ConfirmerMediaPublicationDto,
  ) {
    return this.publicationsService.confirmerMedia(utilisateur.id, id, dto);
  }

  /** Brouillon → en ligne (médias complets exigés selon le type). */
  @RequiertIdempotenceKey()
  @Vendeur()
  @Post('boutique/publications/:id/publier')
  @HttpCode(HttpStatus.OK)
  publier(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.publicationsService.publier(utilisateur.id, id);
  }

  @Vendeur()
  @Delete('boutique/publications/:id/media/:mediaId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async retirerMedia(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('mediaId', ParseUUIDPipe) mediaId: string,
  ): Promise<void> {
    await this.publicationsService.retirerMedia(utilisateur.id, id, mediaId);
  }

  // ── Modération ────────────────────────────────────────────────────────────

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Get('admin/publications')
  listerPourModeration(
    @Query('statut', new ParseEnumPipe(StatutPublication, { optional: true }))
    statut?: StatutPublication,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.publicationsService.listerPourModeration(
      statut,
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 100),
    );
  }

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Patch('admin/publications/:id/statut')
  moderer(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ModerationPublicationDto,
  ) {
    return this.publicationsService.moderer(id, dto.statut);
  }
}
