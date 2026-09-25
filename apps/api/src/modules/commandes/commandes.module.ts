import { Module } from '@nestjs/common';
import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { CommandeController } from './commande.controller.js';
import { CommandeService } from './commande.service.js';

@Module({ imports: [PrismaModule], controllers: [CommandeController], providers: [CommandeService] })
export class CommandesModule {}