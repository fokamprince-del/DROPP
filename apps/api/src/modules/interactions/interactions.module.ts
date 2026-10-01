import { Module } from '@nestjs/common';
import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { StockageModule } from '../../infrastructure/stockage/stockage.module.js';
import { InteractionsController } from './interactions.controller.js';

import { CommentaireService } from './uses-cases/commentaire.service.js';
import { FavoriProduitService } from './uses-cases/favori-produit.service.js';
import { FavoriPublicationService } from './uses-cases/favori-publication.service.js';
import { ListerCommentairesService } from './uses-cases/lister-commenters.service.js';
import { PartagerPublicationService } from './uses-cases/partages.service.js';
import { LikeService } from './uses-cases/like.service.js';
import { AbonnementService } from './uses-cases/abonnement.service.js';
import { EtatsUtilisateurService } from './uses-cases/etats.service.js';

@Module({
  imports: [PrismaModule, StockageModule],
  controllers: [InteractionsController],
  providers: [
    AbonnementService,
    CommentaireService,
    EtatsUtilisateurService,
    FavoriProduitService,
    FavoriPublicationService,
    LikeService,
    ListerCommentairesService,
    PartagerPublicationService,
  ],
})
export class InteractionsModule {}
