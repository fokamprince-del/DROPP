import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseBoolPipe,
  ParseEnumPipe,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';

import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { Public } from '../auth/decorators/public.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';

import { AjusterStockDto } from './dto/ajuster-stock.dto.js';
import {
  TRIS_CATALOGUE,
  type TriCatalogue,
} from './use-cases/catalogue-public.service.js';
import { ConfirmerMediaDto } from './dto/confirmer-media.dto.js';
import { CreerProduitDto } from './dto/creer-produit.dto.js';
import { CreerVarianteDto } from './dto/creer-variante.dto.js';
import { DemanderSignatureDto } from './dto/demander-signature.dto.js';
import { ModifierProduitDto } from './dto/modifier-produit.dto.js';
import { ModifierVarianteDto } from './dto/modifier-variante.dto.js';

import { BoutiqueResolverService } from './services/boutique-resolver.service.js';
import { AjusterStockService } from './use-cases/ajuster-stock.service.js';
import { CataloguePublicService } from './use-cases/catalogue-public.service.js';
import { ConfirmerMediaService } from './use-cases/confirmer-media.service.js';
import { CreerProduitService } from './use-cases/creer-produit.service.js';
import { CreerVarianteService } from './use-cases/creer-variante.service.js';
import { DemanderSignatureMediaService } from './use-cases/demander-signature-media.service.js';
import { DetailProduitService } from './use-cases/detail-produit.service.js';
import { ListerProduitsBoutiqueService } from './use-cases/lister-produits-boutique.service.js';
import { ModifierProduitService } from './use-cases/modifier-produit.service.js';
import { ModifierVarianteService } from './use-cases/modifier-variante.service.js';
import { SupprimerMediaService } from './use-cases/supprimer-media.service.js';
import { SupprimerProduitService } from './use-cases/supprimer-produit.service.js';
import { SupprimerVarianteService } from './use-cases/supprimer-variante.service.js';
import { Vendeur } from '../auth/decorators/profils.decorator.js';
import { RequiertIdempotenceKey } from '../../infrastructure/idempotence/idempotence.decorator.js';

@Controller()
export class ProduitsController {
  constructor(
    private readonly boutiqueResolver: BoutiqueResolverService,
    private readonly cataloguePublic: CataloguePublicService,
    private readonly creerProduit: CreerProduitService,
    private readonly modifierProduit: ModifierProduitService,
    private readonly supprimerProduit: SupprimerProduitService,
    private readonly listerProduits: ListerProduitsBoutiqueService,
    private readonly detailProduit: DetailProduitService,
    private readonly creerVariante: CreerVarianteService,
    private readonly modifierVariante: ModifierVarianteService,
    private readonly supprimerVariante: SupprimerVarianteService,
    private readonly ajusterStock: AjusterStockService,
    private readonly demanderSignature: DemanderSignatureMediaService,
    private readonly confirmerMedia: ConfirmerMediaService,
    private readonly supprimerMedia: SupprimerMediaService,
  ) {}

  // ── Catalogue public ──────────────────────────────────────────────────────

  @Public()
  @Get('produits')
  catalogue(
    @Query('categorieId', new ParseUUIDPipe({ optional: true }))
    categorieId?: string,
    @Query('boutiqueId', new ParseUUIDPipe({ optional: true }))
    boutiqueId?: string,
    @Query('q') q?: string,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
    @Query('prixMin', new ParseIntPipe({ optional: true })) prixMin?: number,
    @Query('prixMax', new ParseIntPipe({ optional: true })) prixMax?: number,
    @Query('tri', new ParseEnumPipe(TRIS_CATALOGUE, { optional: true }))
    tri?: TriCatalogue,
    @Query('enStock', new ParseBoolPipe({ optional: true })) enStock?: boolean,
    @CurrentUser() u?: UtilisateurConnecte,
  ) {
    return this.cataloguePublic.executer({
      categorieId,
      boutiqueId,
      prixMin: prixMin !== undefined ? Math.max(prixMin, 0) : undefined,
      prixMax: prixMax !== undefined ? Math.max(prixMax, 0) : undefined,
      tri,
      enStock,
      q: q?.trim().slice(0, 100) || undefined,
      page: Math.max(page, 1),
      limite: Math.min(Math.max(limite, 1), 100),
      utilisateurId: u?.id,
    });
  }

  @Public()
  @Get('produits/:id')
  detail(@Param('id', ParseUUIDPipe) id: string) {
    return this.detailProduit.executer(id);
  }

  // ── Produits vendeur ──────────────────────────────────────────────────────

  @RequiertIdempotenceKey()
  @Vendeur()
  @Post('boutique/produits')
  @HttpCode(HttpStatus.CREATED)
  async creer(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: CreerProduitDto,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.creerProduit.executer(boutique, dto);
  }

  @Vendeur()
  @Get('boutique/produits')
  async lister(@CurrentUser() u: UtilisateurConnecte) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.listerProduits.executer(boutique);
  }

  @Vendeur()
  @Get('boutique/produits/:id')
  async detailVendeur(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.detailProduit.executer(id, boutique);
  }

  @Vendeur()
  @Patch('boutique/produits/:id')
  async modifier(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ModifierProduitDto,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.modifierProduit.executer(id, boutique, dto);
  }

  @Vendeur()
  @Delete('boutique/produits/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async supprimer(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.supprimerProduit.executer(id, boutique);
  }

  /** Retire le produit de la vente (réversible). */
  @Vendeur()
  @Post('boutique/produits/:id/archiver')
  @HttpCode(HttpStatus.OK)
  async archiver(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.modifierProduit.archiver(id, boutique);
  }

  /** Remet en vente un produit archivé (republié s'il est complet). */
  @Vendeur()
  @Post('boutique/produits/:id/restaurer')
  @HttpCode(HttpStatus.OK)
  async restaurer(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.modifierProduit.restaurer(id, boutique);
  }

  // ── Variantes ─────────────────────────────────────────────────────────────
  @RequiertIdempotenceKey()
  @Vendeur()
  @Post('boutique/produits/:id/variantes')
  @HttpCode(HttpStatus.CREATED)
  async ajouterVariante(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) produitId: string,
    @Body() dto: CreerVarianteDto,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.creerVariante.executer(produitId, boutique, dto);
  }

  @Vendeur()
  @Patch('boutique/produits/:id/variantes/:varianteId')
  async mettreAJourVariante(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) produitId: string,
    @Param('varianteId', ParseUUIDPipe) varianteId: string,
    @Body() dto: ModifierVarianteDto,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.modifierVariante.executer(produitId, varianteId, boutique, dto);
  }

  @Vendeur()
  @Delete('boutique/produits/:id/variantes/:varianteId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async retirerVariante(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) produitId: string,
    @Param('varianteId', ParseUUIDPipe) varianteId: string,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.supprimerVariante.executer(produitId, varianteId, boutique);
  }

  // ── Stock ─────────────────────────────────────────────────────────────────

  @Vendeur()
  @Patch('boutique/produits/:id/variantes/:varianteId/stock')
  async mettreAJourStock(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) produitId: string,
    @Param('varianteId', ParseUUIDPipe) varianteId: string,
    @Body() dto: AjusterStockDto,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.ajusterStock.executer(produitId, varianteId, boutique, dto);
  }

  // ── Médias ────────────────────────────────────────────────────────────────

  @Vendeur()
  @Post('boutique/medias/signature')
  @HttpCode(HttpStatus.OK)
  async obtenirSignature(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: DemanderSignatureDto,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.demanderSignature.executer(boutique, dto);
  }

  @RequiertIdempotenceKey()
  @Vendeur()
  @Post('boutique/medias/confirmer')
  @HttpCode(HttpStatus.CREATED)
  async validerMedia(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: ConfirmerMediaDto,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.confirmerMedia.executer(boutique, dto);
  }

  @Vendeur()
  @Delete('boutique/produits/:id/medias/:mediaId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async retirerMedia(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) produitId: string,
    @Param('mediaId', ParseUUIDPipe) mediaId: string,
  ) {
    const boutique = await this.boutiqueResolver.resoudre(u.id);
    return this.supprimerMedia.executer(produitId, mediaId, boutique);
  }
}
