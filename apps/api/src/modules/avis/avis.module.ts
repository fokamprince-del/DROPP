import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { StockageModule } from '../../infrastructure/stockage/stockage.module.js';
import { AuthentificationModule } from '../auth/auth.module.js';
import { AvisController } from './avis.controller.js';
import { AvisService } from './avis.service.js';

@Module({
  imports: [PrismaModule, StockageModule, AuthentificationModule],
  controllers: [AvisController],
  providers: [AvisService],
})
export class AvisModule {}
