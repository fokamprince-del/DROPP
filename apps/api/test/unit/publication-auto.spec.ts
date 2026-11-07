import { Prisma } from '@dropp/database';

import type { PrismaService } from '../../src/infrastructure/database/prisma.service.js';
import { PublicationAutoService } from '../../src/modules/produits/services/publication-auto.service.js';

const D = (n: number) => new Prisma.Decimal(n);

function service(produit: Record<string, unknown> | null) {
  const mises: unknown[] = [];
  const prisma = {
    produit: {
      findUnique: async () => produit,
      updateMany: async (args: unknown) => {
        mises.push(args);
        return { count: 1 };
      },
    },
  } as unknown as PrismaService;
  return { s: new PublicationAutoService(prisma), mises };
}

const complet = {
  description: 'Une description suffisante',
  prixBase: D(5000),
  variantes: [{ prix: null, stockDisponible: 3 }],
  medias: [{ media: { statutTraitement: 'PRET' } }],
};

describe('PublicationAutoService', () => {
  it('publie un brouillon complet', async () => {
    const { s, mises } = service({ ...complet, statut: 'BROUILLON' });
    await s.tenter('p');
    expect(mises).toEqual([
      { where: { id: 'p', statut: 'BROUILLON' }, data: { statut: 'PUBLIE' } },
    ]);
  });

  it('repasse en brouillon un produit publié devenu incomplet', async () => {
    const { s, mises } = service({ ...complet, statut: 'PUBLIE', medias: [] });
    await s.tenter('p');
    expect(mises).toEqual([
      { where: { id: 'p', statut: 'PUBLIE' }, data: { statut: 'BROUILLON' } },
    ]);
  });

  it('ne touche ni un produit archivé ni un produit rejeté par la modération', async () => {
    for (const statut of ['ARCHIVE', 'REJETE']) {
      const { s, mises } = service({ ...complet, statut });
      await s.tenter('p');
      expect(mises).toHaveLength(0);
    }
  });

  it('exige un prix strictement positif', async () => {
    const { s, mises } = service({
      ...complet,
      statut: 'BROUILLON',
      prixBase: D(0),
      variantes: [{ prix: null, stockDisponible: 3 }],
    });
    await s.tenter('p');
    expect(mises).toHaveLength(0);
  });
});
