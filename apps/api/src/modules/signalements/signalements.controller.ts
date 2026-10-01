import {
  Body,
  Controller,
  Get,
  ParseIntPipe,
  Post,
  Query,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';

import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { Public } from '../auth/decorators/public.decorator.js';
import { RequiertTelephoneVerifie } from '../auth/decorators/require-telephone-verifie.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { CreerSignalementDto } from './dto/creer-signalement.dto.js';
import { SignalementsService } from './signalements.service.js';

/** Côté utilisateur uniquement. Le traitement (modération) relève du back-office admin. */
@Controller()
export class SignalementsController {
  constructor(private readonly signalements: SignalementsService) {}

  @Public()
  @Get('signalements/motifs')
  motifs() {
    return this.signalements.listerMotifs();
  }

  @RequiertTelephoneVerifie()
  @Throttle({ court: { ttl: 60_000, limit: 10 } })
  @Post('signalements')
  creer(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: CreerSignalementDto,
  ) {
    return this.signalements.creer(u.id, dto);
  }

  @Get('moi/signalements')
  listerMiens(
    @CurrentUser() u: UtilisateurConnecte,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.signalements.listerMiens(
      u.id,
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 50),
    );
  }
}
