import { Module } from '@nestjs/common';
import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { QueueModule } from '../../infrastructure/queue/queue.module.js';
import { CommandeExpirationProcessor } from './commande-expiration.processor.js';
import { CommandeController, VentesController } from './commande.controller.js';
import { CommandeService } from './commande.service.js';
import { ParametresModule } from '../parametres/parametres.module.js';

@Module({
  imports: [PrismaModule, QueueModule, ParametresModule],
  controllers: [CommandeController, VentesController],
  providers: [CommandeService, CommandeExpirationProcessor],
})
export class CommandesModule {}
