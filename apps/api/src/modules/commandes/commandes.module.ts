import { Module } from '@nestjs/common';
import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { QueueModule } from '../../infrastructure/queue/queue.module.js';
import { CommandeExpirationProcessor } from './commande-expiration.processor.js';
import { CommandeController } from './commande.controller.js';
import { CommandeService } from './commande.service.js';

@Module({
  imports: [PrismaModule, QueueModule],
  controllers: [CommandeController],
  providers: [CommandeService, CommandeExpirationProcessor],
})
export class CommandesModule {}
