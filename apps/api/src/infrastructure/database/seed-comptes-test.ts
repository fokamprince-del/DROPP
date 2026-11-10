// Fichier .env local si présent (dev) ; sinon variables d'environnement.
try {
  process.loadEnvFile('.env');
} catch {
  // pas de .env : normal en production
}
import { PrismaClient } from '@dropp/database';
import { PrismaPg } from '@prisma/adapter-pg';

import { creerComptesTest } from './comptes-test.js';

const prisma = new PrismaClient({
  adapter: new PrismaPg({
    connectionString: process.env.DATABASE_URL!,
  }),
});

/**
 * Lancement manuel des comptes de test (client, vendeur, dev).
 * L'API les crée aussi toute seule au démarrage (ComptesTestService).
 *   Local : pnpm api:build && pnpm db:seed:comptes-test
 */
await creerComptesTest(prisma)
  .catch((erreur: unknown) => {
    console.error(erreur);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
