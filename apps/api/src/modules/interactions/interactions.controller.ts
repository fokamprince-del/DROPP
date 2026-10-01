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

import { Client, Vendeur } from '../auth/decorators/profils.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { Public } from '../auth/decorators/public.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';

import { CommenterDto } from './dto/commenter.dto.js';
import { PartagerDto } from './dto/partager.dto.js';

import { FavoriPublicationService } from './uses-cases/favori-publication.service.js';
import { ListerCommentairesService } from './uses-cases/lister-commenters.service.js';
import { PartagerPublicationService } from './uses-cases/partages.service.js';
import { AbonnementService } from './uses-cases/abonnement.service.js';
import { CommentaireService } from './uses-cases/commentaire.service.js';
import { LikeService } from './uses-cases/like.service.js';
import { FavoriProduitService } from './uses-cases/favori-produit.service.js';
import { EtatsUtilisateurService } from './uses-cases/etats.service.js';

@Controller()
export class InteractionsController {
  constructor(
    private readonly likeservice: LikeService,
    private readonly commentaireService: CommentaireService,
    private readonly listerCommentaires: ListerCommentairesService,
    private readonly abonnementservice: AbonnementService,
    private readonly favoriPublication: FavoriPublicationService,
    private readonly favoriProduit: FavoriProduitService,
    private readonly partagerPublication: PartagerPublicationService,
    private readonly etatsUtilisateur: EtatsUtilisateurService,
  ) {}

  @Client()
  @Get('moi/etats')
  etats(@CurrentUser() u: UtilisateurConnecte) {
    return this.etatsUtilisateur.executer(u.id);
  }

  // ── Likes publications ────────────────────────────────────────────────────

  @Client()
  @Post('publications/:id/like')
  @HttpCode(HttpStatus.OK)
  likerPub(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.likeservice.likerPublication(u.id, id);
  }

  @Client()
  @Delete('publications/:id/like')
  @HttpCode(HttpStatus.OK)
  unlikerPub(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.likeservice.unlikerPublication(u.id, id);
  }

  // ── Commentaires ──────────────────────────────────────────────────────────

  @Public()
  @Get('publications/:id/commentaires')
  listerComm(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @CurrentUser() u?: UtilisateurConnecte,
  ) {
    return this.listerCommentaires.executer(id, page, u?.id);
  }

  @Public()
  @Get('commentaires/:id/reponses')
  listerReponses(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @CurrentUser() u?: UtilisateurConnecte,
  ) {
    return this.listerCommentaires.listerReponses(id, page, u?.id);
  }

  @Client()
  @Post('publications/:id/commentaires')
  @HttpCode(HttpStatus.CREATED)
  commenter(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CommenterDto,
  ) {
    return this.commentaireService.commenter(u.id, id, dto);
  }

  @Client()
  @Delete('commentaires/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  supprimerComm(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.commentaireService.supprimer(u.id, id);
  }

  // ── Likes commentaires ────────────────────────────────────────────────────

  @Client()
  @Post('commentaires/:id/like')
  @HttpCode(HttpStatus.OK)
  likerComm(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.likeservice.likerCommentaire(u.id, id);
  }

  @Client()
  @Delete('commentaires/:id/like')
  @HttpCode(HttpStatus.OK)
  unlikerComm(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.likeservice.unlikerCommentaire(u.id, id);
  }

  // ── Abonnements ───────────────────────────────────────────────────────────

  @Client()
  @Post('vendeurs/:id/suivre')
  @HttpCode(HttpStatus.OK)
  suivre(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.abonnementservice.suivre(u.id, id);
  }

  @Client()
  @Delete('vendeurs/:id/suivre')
  @HttpCode(HttpStatus.OK)
  nePlusSuivre(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.abonnementservice.nePlusSuivre(u.id, id);
  }

  @Get('moi/abonnements')
  mesAbonnements(
    @CurrentUser() u: UtilisateurConnecte,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.abonnementservice.listerMesAbonnements(
      u.id,
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 50),
    );
  }

  @Vendeur()
  @Get('boutique/abonnes')
  mesAbonnes(
    @CurrentUser() u: UtilisateurConnecte,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.abonnementservice.listerMesAbonnes(
      u.id,
      Math.max(page, 1),
      Math.min(Math.max(limite, 1), 50),
    );
  }

  // ── Favoris publications ──────────────────────────────────────────────────

  @Client()
  @Post('publications/:id/favori')
  @HttpCode(HttpStatus.OK)
  ajouterFavoriPub(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.favoriPublication.ajouter(u.id, id);
  }

  @Client()
  @Delete('publications/:id/favori')
  @HttpCode(HttpStatus.OK)
  retirerFavoriPub(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.favoriPublication.retirer(u.id, id);
  }

  @Client()
  @Get('moi/favoris/publications')
  listerFavorisPubs(
    @CurrentUser() u: UtilisateurConnecte,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
  ) {
    return this.favoriPublication.lister(u.id, page);
  }

  // ── Favoris produits ──────────────────────────────────────────────────────

  @Client()
  @Post('produits/:id/favori')
  @HttpCode(HttpStatus.OK)
  ajouterFavoriProduit(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.favoriProduit.ajouter(u.id, id);
  }

  @Client()
  @Delete('produits/:id/favori')
  @HttpCode(HttpStatus.OK)
  retirerFavoriProduit(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.favoriProduit.retirer(u.id, id);
  }

  @Client()
  @Get('moi/favoris/produits')
  listerFavorisProduits(
    @CurrentUser() u: UtilisateurConnecte,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
  ) {
    return this.favoriProduit.lister(u.id, page);
  }

  // ── Partage ───────────────────────────────────────────────────────────────

  @Client()
  @Post('publications/:id/partager')
  @HttpCode(HttpStatus.OK)
  partager(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: PartagerDto,
  ) {
    return this.partagerPublication.executer(u.id, id, dto);
  }
}
