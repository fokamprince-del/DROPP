// Fichier .env local si présent (dev) ; sinon variables d'environnement.
try {
  process.loadEnvFile('.env');
} catch {
  // pas de .env : normal en production
}
import { PrismaClient } from '@dropp/database';
import { PrismaPg } from '@prisma/adapter-pg';

import { creerDemo, supprimerDemo } from './demo.js';

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! }),
});

/**
 * Lancement manuel du contenu de démo (boutiques, produits, publications, reels).
 * L'API le crée aussi toute seule au démarrage si SEED_DEMO=true.
 *   Local : pnpm api:build && pnpm db:seed:demo
 *   Tout recréer : pnpm db:seed:demo -- --reset
 *   Tout supprimer : pnpm db:seed:demo -- --supprimer
 */
async function main() {
  const args = process.argv.slice(2);
  if (args.includes('--supprimer') || args.includes('--reset')) {
    await supprimerDemo(prisma);
    if (args.includes('--supprimer')) return;
  }
  await creerDemo(prisma);
}

await main()
  .catch((erreur: unknown) => {
    console.error(erreur);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
