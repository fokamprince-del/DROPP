import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { AuthentificationModule } from '../auth/auth.module.js';
import { ClientsController } from './clients.controller.js';
import { ClientsService } from './clients.service.js';

@Module({
  imports: [PrismaModule, AuthentificationModule],
  controllers: [ClientsController],
  providers: [ClientsService],
})
export class ClientsModule {}
