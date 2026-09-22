import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';

import { AppModule } from './app.module.js';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  const config = app.get(ConfigService);

  const trustProxy = config.getOrThrow<number>('app.trustProxy');
  if (trustProxy > 0) app.set('trust proxy', trustProxy);

  app.use(helmet());

  const origins = config.getOrThrow<string[]>('app.corsOrigins');
  if (origins.length > 0) {
    app.enableCors({ origin: origins, maxAge: 600 });
  }

  app.enableShutdownHooks();

  const port = config.getOrThrow<number>('app.port');
  await app.listen(port);
}

await bootstrap();