import { BadRequestException } from '@nestjs/common';

import type {
  MetadonneesFichier,
  StockageProvider,
} from '../../src/infrastructure/stockage/stockage-provider.contract.js';
import { verifierUpload } from '../../src/infrastructure/stockage/verifier-upload.js';

function stockage(meta: MetadonneesFichier | null) {
  const supprimes: string[] = [];
  const marques: string[] = [];
  const s = {
    metadonnees: async () => meta,
    supprimer: async (cle: string) => void supprimes.push(cle),
    marquerUtilise: async (cle: string) => void marques.push(cle),
  } as unknown as StockageProvider;
  return { s, supprimes, marques };
}

const params = {
  prefixe: 'utilisateurs/u1/profil',
  tailleMaxMo: 5,
  typesMime: ['image/jpeg'],
};

describe('verifierUpload', () => {
  it('refuse une clé hors du dossier attendu ou avec ..', async () => {
    const { s } = stockage({ taille: 10, typeMime: 'image/jpeg' });
    for (const cleStockage of [
      'utilisateurs/u2/profil/x.jpg',
      'utilisateurs/u1/profil/../../u2/x.jpg',
      'utilisateurs/u1/profil//x.jpg',
    ]) {
      await expect(verifierUpload(s, { ...params, cleStockage })).rejects.toBeInstanceOf(
        BadRequestException,
      );
    }
  });

  it('refuse un fichier absent', async () => {
    const { s } = stockage(null);
    await expect(
      verifierUpload(s, { ...params, cleStockage: 'utilisateurs/u1/profil/x.jpg' }),
    ).rejects.toThrow('upload non terminé');
  });

  it('supprime un fichier trop gros ou d’un autre type', async () => {
    const gros = stockage({ taille: 6 * 1024 * 1024, typeMime: 'image/jpeg' });
    await expect(
      verifierUpload(gros.s, { ...params, cleStockage: 'utilisateurs/u1/profil/x.jpg' }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(gros.supprimes).toEqual(['utilisateurs/u1/profil/x.jpg']);

    const autre = stockage({ taille: 10, typeMime: 'text/html' });
    await expect(
      verifierUpload(autre.s, { ...params, cleStockage: 'utilisateurs/u1/profil/x.jpg' }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(autre.supprimes).toHaveLength(1);
  });

  it('accepte un fichier conforme et le marque utilisé', async () => {
    const ok = stockage({ taille: 1024, typeMime: 'image/jpeg' });
    await expect(
      verifierUpload(ok.s, { ...params, cleStockage: 'utilisateurs/u1/profil/x.jpg' }),
    ).resolves.toEqual({ taille: 1024, typeMime: 'image/jpeg' });
    expect(ok.marques).toEqual(['utilisateurs/u1/profil/x.jpg']);
  });
});
