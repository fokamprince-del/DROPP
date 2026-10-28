import { Module } from '@nestjs/common';
import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { CommissionService } from './commission.service.js';
import { ParametresService } from './parametres.service.js';

@Module({
  imports: [PrismaModule], // RedisModule est global
  providers: [ParametresService, CommissionService],
  exports: [ParametresService, CommissionService],
})
export class ParametresModule {}