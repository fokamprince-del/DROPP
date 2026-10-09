import { Controller, Get, Inject, ServiceUnavailableException } from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';
import type { Redis } from 'ioredis';

import { Public } from '../../modules/auth/decorators/public.decorator.js';
import { PrismaService } from '../database/prisma.service.js';
import { REDIS_CLIENT } from '../redis/redis.provider.js';

/** Sonde pour le load balancer / l'orchestrateur (hors préfixe /v1). */
@Controller('sante')
export class SanteController {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  @Public()
  @SkipThrottle()
  @Get()
  async verifier() {
    const [base, redis] = await Promise.all([
      this.prisma.$queryRaw`SELECT 1`.then(() => 'ok' as const, () => 'ko' as const),
      this.redis.ping().then(() => 'ok' as const, () => 'ko' as const),
    ]);
    const resultat = { statut: base === 'ok' && redis === 'ok' ? 'ok' : 'degrade', base, redis };
    if (resultat.statut !== 'ok') throw new ServiceUnavailableException(resultat);
    return resultat;
  }
}
