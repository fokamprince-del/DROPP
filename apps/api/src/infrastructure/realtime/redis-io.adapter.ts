import type { INestApplicationContext } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { Redis } from 'ioredis';

/**
 * Adaptateur Socket.IO adossé à Redis (pub/sub) : un événement émis par une
 * instance de l'API atteint les sockets connectés aux autres instances.
 */
export class RedisIoAdapter extends IoAdapter {
  private fabriqueAdaptateur?: ReturnType<typeof createAdapter>;

  constructor(private readonly app: INestApplicationContext) {
    super(app);
  }

  connecterRedis(): void {
    const config = this.app.get(ConfigService);
    const options = {
      host: config.getOrThrow<string>('redis.host'),
      port: config.getOrThrow<number>('redis.port'),
      password: config.getOrThrow<string>('redis.password'),
    };
    const pub = new Redis(options);
    const sub = pub.duplicate();
    this.fabriqueAdaptateur = createAdapter(pub, sub);
  }

  // Typé depuis IoAdapter : @nestjs/platform-socket.io embarque sa propre
  // version de socket.io, dont les types diffèrent de la dépendance directe.
  override createIOServer(
    port: number,
    options?: Parameters<IoAdapter['createIOServer']>[1],
  ): ReturnType<IoAdapter['createIOServer']> {
    const serveur = super.createIOServer(port, options);
    if (this.fabriqueAdaptateur) {
      (serveur as { adapter: (a: unknown) => void }).adapter(
        this.fabriqueAdaptateur,
      );
    }
    return serveur;
  }
}
