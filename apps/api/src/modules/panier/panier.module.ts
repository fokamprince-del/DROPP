import { Module } from '@nestjs/common';
import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { PanierController } from './panier.controller.js';
import { PanierService } from './panier.service.js';

@Module({ imports: [PrismaModule], controllers: [PanierController], providers: [PanierService], exports: [PanierService] })
export class PanierModule {}