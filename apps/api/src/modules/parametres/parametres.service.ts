import { Inject, Injectable, Logger } from '@nestjs/common';
import type { Redis } from 'ioredis';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { REDIS_CLIENT } from '../../infrastructure/redis/redis.provider.js';
import { erreurValeur, PARAMETRES, type CleParametre } from './parametres.registre.js';

const TTL_CACHE_SECONDES = 300;

@Injectable()
export class ParametresService {
  private readonly logger = new Logger(ParametresService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  async lire(cle: CleParametre): Promise<number> {
    try {
      const enCache = await this.redis.get(this.cleCache(cle));
      const valeur = Number(enCache);
      if (enCache !== null) {
        const erreur = erreurValeur(cle, valeur);

        if (erreur === null) return valeur;

        this.logger.warn(
            `Valeur invalide dans le cache du paramètre "${cle}" : ${enCache}`,
        );

        await this.redis.del(this.cleCache(cle));

      } 
    } catch (erreur) {
      // Le cache est facultatif : une panne Redis ne doit pas bloquer une commande.
      this.logger.warn(`Cache des paramètres indisponible : ${String(erreur)}`);
    }

    const ligne = await this.prisma.parametrePlateforme.findUnique({
      where: { cle },
      select: { valeur: true },
    });
    const valeur = typeof ligne?.valeur === 'number' ? ligne.valeur : PARAMETRES[cle].defaut;

    try {
      await this.redis.set(this.cleCache(cle), String(valeur), 'EX', TTL_CACHE_SECONDES);
    } catch {
      /* cache facultatif */
    }
    return valeur;
  }

  async invalider(cle: CleParametre): Promise<void> {
    try {
      await this.redis.del(this.cleCache(cle));
    } catch (erreur) {
      this.logger.warn(`Invalidation du cache impossible : ${String(erreur)}`);
    }
  }

  private cleCache(cle: CleParametre): string {
    return `dropp:parametre:${cle}`;
  }
}