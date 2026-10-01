import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';

import { AppModule } from './app.module.js';
import { RedisIoAdapter } from './infrastructure/realtime/redis-io.adapter.js';
import { PrismaExceptionFilter } from './infrastructure/http/prisma-exception.filter.js';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
  app.useGlobalFilters(new PrismaExceptionFilter());
  const config = app.get(ConfigService);

  const trustProxy = config.getOrThrow<number>('app.trustProxy');
  if (trustProxy > 0) app.set('trust proxy', trustProxy);

  app.use(helmet());

  const origins = config.getOrThrow<string[]>('app.corsOrigins');
  if (origins.length > 0) {
    app.enableCors({ origin: origins, maxAge: 600 });
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
