import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['log', 'warn', 'error', 'debug'],
  });
  app.enableShutdownHooks();
  Logger.log('Worker démarré et en attente de jobs.', 'Bootstrap');
}

await bootstrap();
