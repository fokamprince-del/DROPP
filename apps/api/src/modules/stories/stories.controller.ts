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
  Post,
  Query,
} from '@nestjs/common';

import { Vendeur } from '../auth/decorators/profils.decorator.js';
import { Public } from '../auth/decorators/public.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { ConfirmerStoryDto } from './dto/confirmer-story.dto.js';
import { CreerStoryDto } from './dto/creer-story.dto.js';
import { StoriesService } from './stories.service.js';

@Controller()
export class StoriesController {
  constructor(private readonly storiesService: StoriesService) {}

  @Public()
  @Get('stories')
  listerPubliques(
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.storiesService.listerPubliques(
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 100),
    );
  }

  /** Barre de stories : boutiques suivies, non vues en premier. */
  @Get('stories/abonnements')
  listerAbonnements(@CurrentUser() utilisateur: UtilisateurConnecte) {
    return this.storiesService.listerAbonnements(utilisateur.id);
  }

  @Post('stories/:id/vue')
  @HttpCode(HttpStatus.OK)
  marquerVue(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.storiesService.marquerVue(utilisateur.id, id);
  }

  @Vendeur()
  @Get('boutique/stories/:id/vues')
  listerVues(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.storiesService.listerVues(utilisateur.id, id);
  }

  @Vendeur()
  @Get('boutique/stories')
  listerMesStories(@CurrentUser() utilisateur: UtilisateurConnecte) {
    return this.storiesService.listerMesStories(utilisateur.id);
  }

  @Vendeur()
  @Post('boutique/stories')
  creer(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Body() dto: CreerStoryDto,
  ) {
    return this.storiesService.creer(utilisateur.id, dto);
  }

  @Vendeur()
  @Post('boutique/stories/:id/media')
  confirmer(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ConfirmerStoryDto,
  ) {
    return this.storiesService.confirmer(utilisateur.id, id, dto);
  }

  @Vendeur()
  @Delete('boutique/stories/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async supprimer(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    await this.storiesService.supprimer(utilisateur.id, id);
  }
}
