import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';

import { creerComptesTest } from './comptes-test.js';
import { creerDemo } from './demo.js';
import { PrismaService } from './prisma.service.js';

/**
 * Données de test créées à chaque démarrage de l'API, donc présentes après
 * chaque déploiement quelle que soit la commande de démarrage :
 *  - comptes de test (SEED_CLIENT_*, SEED_VENDEUR_*, SEED_DEV_*) ;
 *  - contenu de démo (boutiques, produits, publications, reels) si
 *    SEED_DEMO=true, après les comptes (qui likent et commentent la démo).
 * Tout est idempotent. Une erreur est journalisée mais ne bloque jamais le
 * démarrage ; la démo tourne en arrière-plan (téléchargements + envois R2)
 * pour ne pas retarder l'ouverture du port.
 */
@Injectable()
export class ComptesTestService implements OnApplicationBootstrap {
  private readonly logger = new Logger(ComptesTestService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onApplicationBootstrap(): Promise<void> {
    const log = (message: string) => this.logger.log(message);
    try {
      await creerComptesTest(this.prisma, process.env, log);
    } catch (erreur: unknown) {
      this.logger.error('Création des comptes de test échouée', erreur);
    }

    if (process.env.SEED_DEMO === 'true') {
      void creerDemo(this.prisma, process.env, log).catch((erreur: unknown) =>
        this.logger.error('Création du contenu de démo échouée', erreur),
      );
    }
  }
}
