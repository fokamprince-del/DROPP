import { RequestMethod, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';

import { PrismaExceptionFilter } from './infrastructure/http/prisma-exception.filter.js';

/** Version de l'API dans l'URL : les apps installées gardent un contrat stable. */
export const PREFIXE_API = 'v1';

/**
 * Configuration HTTP commune au serveur (main.ts) et aux tests e2e :
 * préfixe, validation, filtres, en-têtes de sécurité, CORS, proxy.
 */
export function configurerApplication(app: NestExpressApplication): void {
  const config = app.get(ConfigService);

  app.setGlobalPrefix(PREFIXE_API, {
    exclude: [{ path: 'sante', method: RequestMethod.GET }],
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
  app.useGlobalFilters(new PrismaExceptionFilter());

  const trustProxy = config.getOrThrow<number>('app.trustProxy');
  if (trustProxy > 0) app.set('trust proxy', trustProxy);

  app.use(helmet());

  const origins = config.getOrThrow<string[]>('app.corsOrigins');
  if (origins.length > 0) {
    app.enableCors({ origin: origins, maxAge: 600 });
  }
}
