import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { StockageModule } from '../../infrastructure/stockage/stockage.module.js';
import { AuthentificationModule } from '../auth/auth.module.js';
import {
  BoutiquesPubliquesController,
  ShopsController,
} from './shops.controller.js';
import { ShopsService } from './shops.service.js';

@Module({
  imports: [PrismaModule, AuthentificationModule, StockageModule],
  controllers: [ShopsController, BoutiquesPubliquesController],
  providers: [ShopsService],
})
export class ShopsModule {}
