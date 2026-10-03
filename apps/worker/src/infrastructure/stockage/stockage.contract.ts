export interface StockageProvider {
  recupererBuffer(cleStockage: string): Promise<Buffer | null>;
}

/** Préfixes stockés dans le bucket privé (jamais d'URL publique). */
export const PREFIXES_PRIVES = ['kyc/'] as const;
export const estCleePrivee = (cleStockage: string) =>
  PREFIXES_PRIVES.some((p) => cleStockage.startsWith(p));
export const STOCKAGE_PROVIDER = Symbol('STOCKAGE_PROVIDER_KYC');