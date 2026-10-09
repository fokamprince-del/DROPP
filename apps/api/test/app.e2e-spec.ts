import type { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import request from 'supertest';

import { AppModule } from '../src/app.module.js';
import { configurerApplication } from '../src/app.setup.js';

/**
 * Nécessite Postgres + Redis (docker compose up) et apps/api/.env.
 * Lancer : pnpm api:test:e2e
 */
describe('API (e2e)', () => {
  let app: NestExpressApplication;

  beforeAll(async () => {
    const module = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = module.createNestApplication<NestExpressApplication>();
    configurerApplication(app);
    await app.init();
  });

  afterAll(async () => {
    await app?.close();
  });

  it('GET /sante : base et Redis joignables (hors préfixe /v1)', () =>
    request(app.getHttpServer())
      .get('/sante')
      .expect(200)
      .expect({ statut: 'ok', base: 'ok', redis: 'ok' }));

  it('les routes sont versionnées sous /v1', async () => {
    await request(app.getHttpServer()).get('/categories').expect(404);
    await request(app.getHttpServer()).get('/v1/categories').expect(200);
  });

  it('route protégée sans jeton : 401', () =>
    request(app.getHttpServer()).get('/v1/auth/me').expect(401));

  it('statistiques admin inaccessibles sans rôle', () =>
    request(app.getHttpServer()).get('/v1/admin/stats').expect(401));

  it('corps non conforme : 400 (validation stricte)', () =>
    request(app.getHttpServer())
      .post('/v1/auth/connexion')
      .send({ identifiant: 'x', motDePasse: 'court', inconnu: true })
      .expect(400));
});
