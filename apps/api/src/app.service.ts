import { Injectable } from '@nestjs/common';

import { PrismaService } from './infrastructure/database/prisma.service.js';

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  async getHello(): Promise<string> {
    await this.prisma.$queryRaw`SELECT 1`;

    return 'DROPP API — database connected';
  }
}