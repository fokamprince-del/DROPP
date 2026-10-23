import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

import { AppModule } from './app.module.js';
import { configurerApplication, PREFIXE_API } from './app.setup.js';
import { RedisIoAdapter } from './infrastructure/realtime/redis-io.adapter.js';
import { writeFileSync } from 'node:fs';
import { configurerOpenApi } from './infrastructure/http/openapi.js';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const config = app.get(ConfigService);

  configurerApplication(app);

  // Documentation OpenAPI (génération du client Dart) : hors production.
  if (config.getOrThrow<string>('app.environment') !== 'production') {
    configurerOpenApi(app, PREFIXE_API);
  }

  // Socket.IO multi-instances via Redis pub/sub.
  const adaptateurIo = new RedisIoAdapter(app);
  adaptateurIo.connecterRedis();
  app.useWebSocketAdapter(adaptateurIo);

  app.enableShutdownHooks();

  const port = config.getOrThrow<number>('app.port');
  await app.listen(port);
}

await bootstrap();
