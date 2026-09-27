import {
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';

import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { Public } from '../auth/decorators/public.decorator.js';
import { RequiertTelephoneVerifie } from '../auth/decorators/require-telephone-verifie.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { LikesService } from './likes.service.js';

@Controller('publications/:publicationId/likes')
export class LikesController {
  constructor(private readonly likesService: LikesService) {}

  @Public()
  @Get()
  compter(@Param('publicationId', ParseUUIDPipe) publicationId: string) {
    return this.likesService.compter(publicationId);
  }

  @RequiertTelephoneVerifie()
  @Get('me')
  obtenirEtat(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('publicationId', ParseUUIDPipe) publicationId: string,
  ) {
    return this.likesService.obtenirEtat(utilisateur.id, publicationId);
  }

  @RequiertTelephoneVerifie()
  @Post()
  aimer(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('publicationId', ParseUUIDPipe) publicationId: string,
  ) {
    return this.likesService.aimer(utilisateur.id, publicationId);
  }

  @RequiertTelephoneVerifie()
  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  async retirer(
    @CurrentUser() utilisateur: UtilisateurConnecte,
    @Param('publicationId', ParseUUIDPipe) publicationId: string,
  ): Promise<void> {
    await this.likesService.retirer(utilisateur.id, publicationId);
  }
}
