import { Body, Controller, Get, Patch, Req } from '@nestjs/common';
import type { Request } from 'express';

import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { MiseAJourProfilDto } from './dto/mise-a-jour-profil.dto.js';
import { UsersService } from './users.service.js';

type RequeteAuthentifiee = Request & {
  user: UtilisateurConnecte;
};

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  obtenirProfil(@Req() requete: RequeteAuthentifiee) {
    return this.usersService.obtenirProfil(requete.user.id);
  }

  @Patch('me')
  mettreAJourProfil(
    @Req() requete: RequeteAuthentifiee,
    @Body() dto: MiseAJourProfilDto,
  ) {
    return this.usersService.mettreAJourProfil(requete.user.id, dto);
  }
}
