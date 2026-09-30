import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseBoolPipe,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
} from '@nestjs/common';

import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import {
  EnregistrerAppareilDto,
  RetirerAppareilDto,
} from './dto/enregistrer-appareil.dto.js';
import { ModifierPreferencesDto } from './dto/modifier-preferences.dto.js';
import { NotificationsService } from './notifications.service.js';

@Controller()
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get('notifications')
  lister(
    @CurrentUser() u: UtilisateurConnecte,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
    @Query('nonLues', new ParseBoolPipe({ optional: true })) nonLues = false,
  ) {
    return this.notifications.lister(
      u.id,
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 50),
      nonLues,
    );
  }

  @Get('notifications/compteur')
  compteur(@CurrentUser() u: UtilisateurConnecte) {
    return this.notifications.compteur(u.id);
  }

  @Post('notifications/tout-lire')
  @HttpCode(HttpStatus.OK)
  toutLire(@CurrentUser() u: UtilisateurConnecte) {
    return this.notifications.toutLire(u.id);
  }

  @Get('notifications/preferences')
  preferences(@CurrentUser() u: UtilisateurConnecte) {
    return this.notifications.listerPreferences(u.id);
  }

  @Put('notifications/preferences')
  modifierPreferences(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: ModifierPreferencesDto,
  ) {
    return this.notifications.modifierPreferences(u.id, dto);
  }

  @Patch('notifications/:id/lue')
  marquerLue(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.notifications.marquerLue(u.id, id);
  }

  @Delete('notifications/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  supprimer(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.notifications.supprimer(u.id, id);
  }

  // ── Appareils ─────────────────────────────────────────────────────────────

  /** À appeler après la connexion et à chaque rafraîchissement du jeton FCM. */
  @Post('appareils')
  enregistrerAppareil(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: EnregistrerAppareilDto,
  ) {
    return this.notifications.enregistrerAppareil(u.id, dto);
  }

  /** À appeler avant la déconnexion (le jeton peut contenir des « : », d'où le body). */
  @Post('appareils/retirer')
  @HttpCode(HttpStatus.NO_CONTENT)
  retirerAppareil(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: RetirerAppareilDto,
  ) {
    return this.notifications.retirerAppareil(u.id, dto.tokenFcm);
  }
}
