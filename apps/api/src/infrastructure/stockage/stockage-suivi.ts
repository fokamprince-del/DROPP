import { Logger } from '@nestjs/common';
import type { Redis } from 'ioredis';

import type {
  MetadonneesFichier,
  SignatureUpload,
  StockageProvider,
} from './stockage-provider.contract.js';

export const CLE_UPLOADS_EN_ATTENTE = 'dropp:stockage:uploads-en-attente';

/**
 * Décore le provider réel : chaque URL d'upload signée est notée dans Redis
 * (sorted set, score = date) jusqu'à sa confirmation. Le nettoyage périodique
 * supprime du bucket les fichiers uploadés mais jamais confirmés.
 */
export class StockageSuivi implements StockageProvider {
  private readonly logger = new Logger(StockageSuivi.name);

  constructor(
    private readonly interne: StockageProvider,
    private readonly redis: Redis,
  ) {}

  async genererSignatureUpload(
    repertoire: string,
    typeMime: string,
    tailleMo: number,
  ): Promise<SignatureUpload> {
    const signature = await this.interne.genererSignatureUpload(
      repertoire,
      typeMime,
      tailleMo,
    );
    await this.redis
      .zadd(CLE_UPLOADS_EN_ATTENTE, Date.now(), signature.cleStockage)
      .catch((e: unknown) => this.logger.warn(`Suivi upload : ${String(e)}`));
    return signature;
  }

  async marquerUtilise(cleStockage: string): Promise<void> {
    await this.redis
      .zrem(CLE_UPLOADS_EN_ATTENTE, cleStockage)
      .catch((e: unknown) => this.logger.warn(`Suivi upload : ${String(e)}`));
  }

  urlPublique(
    cleStockage: string,
    options?: { largeur?: number; hauteur?: number },
  ): string {
    return this.interne.urlPublique(cleStockage, options);
  }

  urlSignee(cleStockage: string, dureeSecondes?: number): Promise<string> {
    return this.interne.urlSignee(cleStockage, dureeSecondes);
  }

  async supprimer(cleStockage: string): Promise<void> {
    await this.interne.supprimer(cleStockage);
    await this.redis.zrem(CLE_UPLOADS_EN_ATTENTE, cleStockage).catch(() => 0);
  }

  metadonnees(cleStockage: string): Promise<MetadonneesFichier | null> {
    return this.interne.metadonnees(cleStockage);
  }

  getFile(cleStockage: string): Promise<Buffer| null> {
    return this.interne.getFile(cleStockage);
  }
}
