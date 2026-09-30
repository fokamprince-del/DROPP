import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseEnumPipe,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
} from '@nestjs/common';

import {
  ConfirmerImageDto,
  SignatureImageDto,
} from '../../infrastructure/stockage/image.dto.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { Vendeur } from '../auth/decorators/profils.decorator.js';
import { Public } from '../auth/decorators/public.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';
import { EnregistrerBoutiqueDto } from './dto/enregistrer-boutique.dto.js';
import { MiseAJourBoutiqueDto } from './dto/mise-a-jour-boutique.dto.js';
import { ShopsService, type TypeImageBoutique } from './shops.service.js';

const TYPES_IMAGE = { logo: 'logo', banniere: 'banniere' } as const;
const typeImagePipe = new ParseEnumPipe(TYPES_IMAGE);

@Controller('shops')
@Vendeur()
export class ShopsController {
  constructor(private readonly shopsService: ShopsService) {}

  @Get('me')
  obtenirMaBoutique(@CurrentUser() u: UtilisateurConnecte) {
    return this.shopsService.obtenirMaBoutique(u.id);
  }

  @Post()
  creerBoutique(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: EnregistrerBoutiqueDto,
  ) {
    return this.shopsService.creerBoutique(u.id, dto);
  }

  @Patch('me')
  mettreAJourMaBoutique(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: MiseAJourBoutiqueDto,
  ) {
    return this.shopsService.mettreAJourMaBoutique(u.id, dto);
  }

  /** :type = logo | banniere */
  @Post('me/:type/signature')
  signatureImage(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('type', typeImagePipe) type: TypeImageBoutique,
    @Body() dto: SignatureImageDto,
  ) {
    return this.shopsService.signatureImage(u.id, type, dto);
  }

  @Put('me/:type')
  confirmerImage(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('type', typeImagePipe) type: TypeImageBoutique,
    @Body() dto: ConfirmerImageDto,
  ) {
    return this.shopsService.confirmerImage(u.id, type, dto.cleStockage);
  }

  @Delete('me/:type')
  supprimerImage(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('type', typeImagePipe) type: TypeImageBoutique,
  ) {
    return this.shopsService.supprimerImage(u.id, type);
  }
}

/** Profil public d'une boutique (visiteurs et utilisateurs connectés). */
@Controller('boutiques')
export class BoutiquesPubliquesController {
  constructor(private readonly shopsService: ShopsService) {}

  @Public()
  @Get()
  rechercher(
    @Query('q') q?: string,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.shopsService.rechercher(
      q?.trim().slice(0, 100) || undefined,
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 50),
    );
  }

  @Public()
  @Get(':id')
  obtenir(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() u?: UtilisateurConnecte,
  ) {
    return this.shopsService.obtenirPublique(id, u?.id);
  }
}
