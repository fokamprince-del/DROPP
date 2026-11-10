import { Module } from '@nestjs/common';

import { ComptesTestService } from './comptes-test.service.js';
import { PrismaService } from './prisma.service.js';

@Module({
  providers: [PrismaService, ComptesTestService],
  exports: [PrismaService],
})
export class PrismaModule {}
