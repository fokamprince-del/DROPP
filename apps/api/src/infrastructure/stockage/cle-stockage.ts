import { randomUUID } from 'node:crypto';

const EXTENSION_PAR_MIME: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'video/mp4': 'mp4',
  'video/quicktime': 'mov',
};

/** Clé unique et non devinable : "<repertoire>/<uuid>.<ext>". */
export function genererCle(repertoire: string, typeMime: string): string {
  const extension = EXTENSION_PAR_MIME[typeMime];
  const base = `${repertoire.replace(/\/+$/, '')}/${randomUUID()}`;
  return extension ? `${base}.${extension}` : base;
}

export function estImage(cleStockage: string): boolean {
  return /\.(jpe?g|png|webp)$/i.test(cleStockage);
}
