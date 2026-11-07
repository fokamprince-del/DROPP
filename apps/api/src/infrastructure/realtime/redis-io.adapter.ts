import { Logger, type INestApplicationContext } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { Redis } from 'ioredis';

/**
 * Adaptateur Socket.IO adossé à Redis (pub/sub) : un événement émis par une
 * instance de l'API atteint les sockets connectés aux autres instances.
 */
export class RedisIoAdapter extends IoAdapter {
  private readonly journal = new Logger(RedisIoAdapter.name);
  private fabriqueAdaptateur?: ReturnType<typeof createAdapter>;
  private origines: string[] = [];

  constructor(private readonly app: INestApplicationContext) {
    super(app);
  }

  connecterRedis(): void {
    const config = this.app.get(ConfigService);
    this.origines = config.getOrThrow<string[]>('app.corsOrigins');
    const options = {
      host: config.getOrThrow<string>('redis.host'),
      port: config.getOrThrow<number>('redis.port'),
      password: config.getOrThrow<string>('redis.password'),
    };
    const pub = new Redis(options);
    const sub = pub.duplicate();
    for (const client of [pub, sub]) {
      client.on('error', (e: Error) =>
        this.journal.error(`Redis (Socket.IO) : ${e.message}`),
      );
    }
    this.fabriqueAdaptateur = createAdapter(pub, sub);
  }

  // Typé depuis IoAdapter : @nestjs/platform-socket.io embarque sa propre
  // version de socket.io, dont les types diffèrent de la dépendance directe.
  override createIOServer(
    port: number,
    options?: Parameters<IoAdapter['createIOServer']>[1],
  ): ReturnType<IoAdapter['createIOServer']> {
    // Mêmes origines que l'API HTTP ; aucune = pas d'en-têtes CORS
    // (les apps mobiles n'en ont pas besoin).
    const serveur = super.createIOServer(port, {
      ...options,
      cors: { origin: this.origines.length > 0 ? this.origines : false },
    } as Parameters<IoAdapter['createIOServer']>[1]);
    if (this.fabriqueAdaptateur) {
      (serveur as { adapter: (a: unknown) => void }).adapter(
        this.fabriqueAdaptateur,
      );
    }
    return serveur;
  }
}
