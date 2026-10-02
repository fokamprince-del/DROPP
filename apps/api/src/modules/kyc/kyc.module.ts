import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { QUEUE_KYC } from '@dropp/contrats';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { StockageModule } from '../../infrastructure/stockage/stockage.module.js';
import { AuthentificationModule } from '../auth/auth.module.js';
import { QueueModule } from '../../infrastructure/queue/queue.module.js';

import { KycController } from './kyc.controller.js';

import { KycStockageService } from './services/kyc-stockage.service.js';
import { OcrService } from './services/ocr.service.js';

import { UploadDocumentService } from './use-cases/upload-document.service.js';
import { ExtraireDonneesCniService } from './use-cases/extraire-donnees-cni.service.js';
import { ConfirmerDonneesCniService } from './use-cases/confirmer-donnees-cni.service.js';
import { SoumettreDoissierService } from './use-cases/soummetre-dossier-kyc.service.js';
import { ConsulterDossierService } from './use-cases/consulter-dossier.service.js';
import { DecisionAdminService } from './use-cases/decision-admin.service.js';

@Module({
  imports: [
    PrismaModule,
    StockageModule,
    QueueModule,
    AuthentificationModule,
    BullModule.registerQueue({ name: QUEUE_KYC }),
  ],
  controllers: [KycController],
  providers: [
    // Services techniques
    KycStockageService,
    OcrService,

    // Cas d'usage
    UploadDocumentService,
    ExtraireDonneesCniService,
    ConfirmerDonneesCniService,
    SoumettreDoissierService,
    ConsulterDossierService,
    DecisionAdminService,
  ],
})
export class KycModule {}