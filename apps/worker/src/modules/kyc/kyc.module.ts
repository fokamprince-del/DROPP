import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { QUEUE_KYC, QUEUE_NOTIFICATION } from '@dropp/contrats';

import { PrismaModule } from '../../infrastructure/database/database/prisma.module.js';
import { KycWorker } from './kyc.worker.js';
import { FaceMatchService } from './services/face-match.service.js';

/** Vérification faciale des dossiers KYC (les images sont lues par URL signée). */
@Module({
  imports: [
    PrismaModule,
    BullModule.registerQueue({ name: QUEUE_KYC }, { name: QUEUE_NOTIFICATION }),
  ],
  providers: [KycWorker, FaceMatchService],
})
export class KycModule {}
