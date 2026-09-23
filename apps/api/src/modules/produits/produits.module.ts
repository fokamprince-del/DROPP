import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { StockageModule } from '../../infrastructure/stockage/stockage.module.js';

import { ProduitsController } from './produits.controller.js';

import { BoutiqueResolverService } from './services/boutique-resolver.service.js';
import { PrixService } from './services/prix.service.js';
import { PublicationAutoService } from './services/publication-auto.service.js';

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

@Module({
  imports: [PrismaModule, StockageModule],
  controllers: [ProduitsController],
  providers: [
    // Services techniques
    BoutiqueResolverService,
    PrixService,
    PublicationAutoService,

    // Cas d'usage
    AjusterStockService,
    CataloguePublicService,
    ConfirmerMediaService,
    CreerProduitService,
    CreerVarianteService,
    DemanderSignatureMediaService,
    DetailProduitService,
    ListerProduitsBoutiqueService,
    ModifierProduitService,
    ModifierVarianteService,
    SupprimerMediaService,
    SupprimerProduitService,
    SupprimerVarianteService,
  ],
  exports: [BoutiqueResolverService, AjusterStockService],
})
export class ProduitsModule {}