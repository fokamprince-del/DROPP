import { Module } from '@nestjs/common';

import { PrismaModule } from '../database/prisma.module.js';
import { SanteController } from './sante.controller.js';

@Module({
  imports: [PrismaModule],
  controllers: [SanteController],
})
export class SanteModule {}
