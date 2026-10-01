import {
  Body,
  Controller,
  Delete,
  Get,
  Patch,
  Post,
  Put,
  Query,
} from '@nestjs/common';

import { Public } from '../auth/decorators/public.decorator.js';

import {
  ConfirmerImageDto,
  SignatureImageDto,
} from '../../infrastructure/stockage/image.dto.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { MiseAJourProfilDto } from './dto/mise-a-jour-profil.dto.js';
import { UsersService } from './users.service.js';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  obtenirProfil(@CurrentUser() u: UtilisateurConnecte) {
    return this.usersService.obtenirProfil(u.id);
  }

  @Public()
  @Get('pseudo-disponible')
  pseudoDisponible(@Query('pseudo') pseudo = '') {
    return this.usersService.pseudoDisponible(pseudo.slice(0, 40));
  }

  @Patch('me')
  mettreAJourProfil(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: MiseAJourProfilDto,
  ) {
    return this.usersService.mettreAJourProfil(u.id, dto);
  }

  /** 1. Obtenir l'URL d'upload, 2. PUT du fichier par l'app, 3. PUT /users/me/photo. */
  @Post('me/photo/signature')
  signaturePhoto(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: SignatureImageDto,
  ) {
    return this.usersService.signaturePhoto(u.id, dto);
  }

  @Put('me/photo')
  confirmerPhoto(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: ConfirmerImageDto,
  ) {
    return this.usersService.confirmerPhoto(u.id, dto.cleStockage);
  }

  @Delete('me/photo')
  supprimerPhoto(@CurrentUser() u: UtilisateurConnecte) {
    return this.usersService.supprimerPhoto(u.id);
  }
}
