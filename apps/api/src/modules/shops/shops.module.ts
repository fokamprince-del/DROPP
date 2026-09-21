import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { AuthentificationModule } from '../auth/auth.module.js';
import { ShopsController } from './shops.controller.js';
import { ShopsService } from './shops.service.js';

@Module({
  imports: [PrismaModule, AuthentificationModule],
  controllers: [ShopsController],
  providers: [ShopsService],
})
export class ShopsModule {}
