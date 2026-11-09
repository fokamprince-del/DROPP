import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';

import { creerComptesTest } from './comptes-test.js';
import { PrismaService } from './prisma.service.js';

/**
 * Crée les comptes de test (SEED_CLIENT_*, SEED_VENDEUR_*, SEED_DEV_*) à
 * chaque démarrage de l'API : ils existent donc après chaque déploiement,
 * quelle que soit la commande de démarrage. Sans ces variables, rien n'est
 * fait. Une erreur est journalisée mais ne bloque jamais le démarrage.
 */
@Injectable()
export class ComptesTestService implements OnApplicationBootstrap {
  private readonly logger = new Logger(ComptesTestService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onApplicationBootstrap(): Promise<void> {
    try {
      await creerComptesTest(this.prisma, process.env, (message) =>
        this.logger.log(message),
      );
    } catch (erreur: unknown) {
      this.logger.error('Création des comptes de test échouée', erreur);
    }
  }
}
