import { Injectable, Logger } from '@nestjs/common';

import { genererCle } from './cle-stockage.js';
import type {
  MetadonneesFichier,
  SignatureUpload,
  StockageProvider,
} from './stockage-provider.contract.js';

/** Stockage factice pour le dev sans R2 (STOCKAGE_DRIVER=stub). */
@Injectable()
export class StockageProviderStub implements StockageProvider {
  private readonly logger = new Logger(StockageProviderStub.name);

  async genererSignatureUpload(
    repertoire: string,
    typeMime: string,
    tailleMo: number,
  ): Promise<SignatureUpload> {
    const cleStockage = genererCle(repertoire, typeMime);
    const expireA = new Date(Date.now() + 10 * 60_000);

    this.logger.debug(
      `[STOCKAGE STUB] Signature générée — clé: ${cleStockage} | mime: ${typeMime} | max: ${tailleMo}Mo`,
    );

    return {
      uploadUrl: `http://localhost:9000/stub-bucket/${cleStockage}`,
      cleStockage,
      expireA,
      enTetes: { 'Content-Type': typeMime },
    };
  }

  urlPublique(
    cleStockage: string,
    options?: { largeur?: number; hauteur?: number },
  ): string {
    const params = options
      ? `?w=${options.largeur ?? ''}&h=${options.hauteur ?? ''}`
      : '';
    return `http://localhost:9000/stub-bucket/${cleStockage}${params}`;
  }

  async supprimer(cleStockage: string): Promise<void> {
    this.logger.debug(`[STOCKAGE STUB] Suppression — clé: ${cleStockage}`);
  }

  async urlSignee(cleStockage: string): Promise<string> {
    return `http://localhost:9000/stub-bucket-prive/${cleStockage}?signature=stub`;
  }

  /** Le stub considère que tout fichier existe (1 octet, type inconnu). */
  async metadonnees(cleStockage: string): Promise<MetadonneesFichier> {
    this.logger.debug(`[STOCKAGE STUB] Métadonnées — clé: ${cleStockage}`);
    return { taille: 1, typeMime: null };
  }
}
