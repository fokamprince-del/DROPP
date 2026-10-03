import { Module } from '@nestjs/common';
import { KycWorker } from './kyc.worker.js';
import { FaceMatchService } from './services/face-match.service.js';
import { QUEUE_KYC } from '@dropp/contrats';
import { BullModule } from '@nestjs/bullmq';
import { StockageModule } from '../../infrastructure/stockage/stockage.module.js';

@Module({
  imports: [
    BullModule.registerQueue({ name: QUEUE_KYC }),
    StockageModule,
  ],
  providers: [
    KycWorker, 
    FaceMatchService,
  ],
})
export class KycModule {}