import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { AuthentificationModule } from '../auth/auth.module.js';
import { SellersController } from './sellers.controller.js';
import { SellersService } from './sellers.service.js';

@Module({
  imports: [PrismaModule, AuthentificationModule],
  controllers: [SellersController],
  providers: [SellersService],
})
export class SellersModule {}
