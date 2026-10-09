import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

import { AppModule } from './app.module.js';
import { configurerApplication, PREFIXE_API } from './app.setup.js';
import { RedisIoAdapter } from './infrastructure/realtime/redis-io.adapter.js';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const config = app.get(ConfigService);

  configurerApplication(app);

  // Documentation OpenAPI (génération du client Dart) : hors production.
  if (config.getOrThrow<string>('app.environment') !== 'production') {
    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder()
        .setTitle('DROPP API')
        .setVersion(PREFIXE_API)
        .addBearerAuth()
        .addSecurityRequirements('bearer')
        .addGlobalParameters({
          name: 'Idempotency-Key',
          in: 'header',
          required: false,
          description:
            'UUID v4 unique par action (obligatoire sur certaines routes POST).',
          schema: { type: 'string' },
        })
        .build(),
    );
    SwaggerModule.setup('docs', app, document, {
      jsonDocumentUrl: 'docs/openapi.json',
    });
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
