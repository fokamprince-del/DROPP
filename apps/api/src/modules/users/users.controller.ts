import {
  Body,
  Controller,
  Get,
  Patch,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';

import { AuthentificationGuard } from '../auth/guards/auth.guard.js';
import type { UtilisateurAuthentifie } from '../auth/types/user-authentified.type.js';
import { MiseAJourProfilDto } from './dto/mise-a-jour-profil.dto.js';
import { UsersService } from './users.service.js';

type RequeteAuthentifiee = Request & {
  user: UtilisateurAuthentifie;
};

@Controller('users')
@UseGuards(AuthentificationGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  obtenirProfil(@Req() requete: RequeteAuthentifiee) {
    return this.usersService.obtenirProfil(requete.user.utilisateurId);
  }

  @Patch('me')
  mettreAJourProfil(
    @Req() requete: RequeteAuthentifiee,
    @Body() dto: MiseAJourProfilDto,
  ) {
    return this.usersService.mettreAJourProfil(
      requete.user.utilisateurId,
      dto,
    );
  }
}
