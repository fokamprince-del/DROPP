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
import { Throttle } from '@nestjs/throttler';

import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { RequiertTelephoneVerifie } from '../auth/decorators/require-telephone-verifie.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { BlocagesService } from './blocages.service.js';
import { ConversationsService } from './conversations.service.js';
import {
  EnvoyerMessageDto,
  OuvrirConversationDto,
  SignaturePieceJointeDto,
} from './dto/messagerie.dto.js';
import { MessagesService } from './messages.service.js';

@Controller()
@RequiertTelephoneVerifie()
export class MessagerieController {
  constructor(
    private readonly conversations: ConversationsService,
    private readonly messages: MessagesService,
    private readonly blocages: BlocagesService,
  ) {}

  // ── Conversations ─────────────────────────────────────────────────────────

  /** Ouvre (ou retrouve) la conversation avec un utilisateur / une boutique. */
  @Post('conversations')
  @HttpCode(HttpStatus.OK)
  ouvrir(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: OuvrirConversationDto,
  ) {
    return this.conversations.ouvrir(u.id, dto.destinataireId);
  }

  @Get('conversations')
  lister(
    @CurrentUser() u: UtilisateurConnecte,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.conversations.lister(
      u.id,
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 50),
    );
  }

  @Get('conversations/non-lus')
  nonLus(@CurrentUser() u: UtilisateurConnecte) {
    return this.conversations.totalNonLus(u.id);
  }

  @Get('conversations/:id')
  detail(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.conversations.detail(u.id, id);
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  @Get('conversations/:id/messages')
  listerMessages(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Query('avant', new ParseUUIDPipe({ optional: true })) avant?: string,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 30,
  ) {
    return this.messages.lister(
      u.id,
      id,
      avant,
      Math.min(Math.max(limite, 1), 100),
    );
  }

  @Throttle({ court: { ttl: 60_000, limit: 60 } })
  @Post('conversations/:id/messages')
  envoyer(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: EnvoyerMessageDto,
  ) {
    return this.messages.envoyer(u.id, id, dto);
  }

  @Throttle({ court: { ttl: 60_000, limit: 30 } })
  @Post('conversations/:id/pieces-jointes/signature')
  signature(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SignaturePieceJointeDto,
  ) {
    return this.messages.signaturePieceJointe(u.id, id, dto);
  }

  @Post('conversations/:id/lu')
  @HttpCode(HttpStatus.OK)
  marquerLus(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.messages.marquerLus(u.id, id);
  }

  // ── Blocages ──────────────────────────────────────────────────────────────

  @Get('moi/bloques')
  listerBloques(@CurrentUser() u: UtilisateurConnecte) {
    return this.blocages.lister(u.id);
  }

  @Post('utilisateurs/:id/bloquer')
  @HttpCode(HttpStatus.OK)
  bloquer(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.blocages.bloquer(u.id, id);
  }

  @Delete('utilisateurs/:id/bloquer')
  debloquer(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.blocages.debloquer(u.id, id);
  }
}
