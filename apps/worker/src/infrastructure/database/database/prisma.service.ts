import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaPg } from '@prisma/adapter-pg';

import { PrismaClient } from '@dropp/database';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor(configService: ConfigService) {
    const connectionString = configService.getOrThrow<string>('database.url');
    const max = configService.getOrThrow<number>('database.poolMax');
    const connectionTimeoutMillis= 50_000;
    const idleTimeoutMillis= 30_000;

    const adapter = new PrismaPg({
      connectionString,
      max,
      connectionTimeoutMillis,
      idleTimeoutMillis,
    });

    super({
      adapter,
      log: ['warn', 'error']
    });
  }

  async onModuleInit(): Promise<void> {
    await this.$connect();
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
