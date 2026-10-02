import { Module } from '@nestjs/common';
import { KycWorker } from './kyc.worker.js';
import { FaceMatchService } from './services/face-match.service.js';
import { QUEUE_KYC } from '@dropp/contrats';
import { BullModule } from '@nestjs/bullmq';

@Module({
  imports: [
    BullModule.registerQueue({ name: QUEUE_KYC }),
  ],
  providers: [KycWorker, FaceMatchService],
})
export class KycModule {}