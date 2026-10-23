import { writeFileSync } from 'node:fs';
import type { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule, type OpenAPIObject } from '@nestjs/swagger';
import { ErreurApiDto } from './erreur-api.dto.js';

const METHODES = ['get', 'post', 'put', 'patch', 'delete'] as const;

const erreur = (description: string) => ({
  description,
  content: {
    'application/json': { schema: { $ref: '#/components/schemas/ErreurApiDto' } },
  },
});

/**
 * Ajoute ce que les guards et pipes GLOBAUX garantissent déjà à l'exécution :
 * - route non @Public()  → exigence Bearer + 401 ; route @Public() → security: []
 * - ThrottlerGuard global → 429 partout
 * - ValidationPipe / ParseUUIDPipe → 400 dès qu'il y a un corps ou des paramètres
 * Les erreurs métier (403, 404, 409) restent déclarées route par route.
 */
function completer(document: OpenAPIObject): OpenAPIObject {
  for (const item of Object.values(document.paths)) {
    for (const methode of METHODES) {
      const operation = item[methode];
      if (!operation) continue;
      const operationAvecExtensions = operation as typeof operation & { 'x-public'?: boolean };

      operation.responses ??= {};

      if (operationAvecExtensions['x-public']) {
        operation.security = [];
        delete operationAvecExtensions['x-public'];
      } else {
        operation.responses['401'] ??= erreur('Jeton d’accès absent, invalide ou expiré.');
      }

      operation.responses['429'] ??= erreur('Trop de requêtes : réessayez plus tard.');

      const aDesEntrees =
        operation.requestBody || operation.parameters?.some((p) => 'in' in p && p.in !== 'header');
      if (aDesEntrees) {
        operation.responses['400'] ??= erreur('Requête invalide (validation des entrées).');
      }
    }
  }
  return document;
}

export function configurerOpenApi(app: INestApplication, version: string): void {
  const document = completer(
    SwaggerModule.createDocument(
      app,
      new DocumentBuilder()
        .setTitle('DROPP API')
        .setVersion(version)
        .addBearerAuth()
        .addSecurityRequirements('bearer') // protégé par défaut, comme le JwtAuthGuard global
        .build(),
      { extraModels: [ErreurApiDto] },
    ),
  );

  SwaggerModule.setup('docs', app, document);
  writeFileSync('openapi.json', JSON.stringify(document, null, 2));
}