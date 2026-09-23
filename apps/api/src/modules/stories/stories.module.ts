import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { StockageModule } from '../../infrastructure/stockage/stockage.module.js';
import { AuthentificationModule } from '../auth/auth.module.js';
import { StoriesController } from './stories.controller.js';
import { StoriesService } from './stories.service.js';

@Module({
  imports: [PrismaModule, StockageModule, AuthentificationModule],
  controllers: [StoriesController],
  providers: [StoriesService],
})
export class StoriesModule {}