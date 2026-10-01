import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { SignalementsController } from './signalements.controller.js';
import { SignalementsService } from './signalements.service.js';

@Module({
  imports: [PrismaModule],
  controllers: [SignalementsController],
  providers: [SignalementsService],
})
export class SignalementsModule {}
