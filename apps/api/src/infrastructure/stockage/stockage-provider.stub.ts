import { Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'node:crypto';

import type {
  SignatureUpload,
  StockageProvider,
} from './stockage-provider.contract.js';

@Injectable()
export class StockageProviderStub implements StockageProvider {
  private readonly logger = new Logger(StockageProviderStub.name);

  async genererSignatureUpload(
    repertoire: string,
    typeMime: string,
    tailleMo: number,
  ): Promise<SignatureUpload> {
    const cleStockage = `${repertoire}/${randomUUID()}`;
    const expireA = new Date(Date.now() + 10 * 60_000);

    this.logger.debug(
      `[STOCKAGE STUB] Signature générée — clé: ${cleStockage} | mime: ${typeMime} | max: ${tailleMo}Mo`,
    );

    return {
      uploadUrl: `http://localhost:9000/stub-bucket/${cleStockage}`,
      cleStockage,
      expireA,
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
}
