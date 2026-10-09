import type { Prisma } from '@dropp/database';

/**
 * Boutique visible du public : active, vendeur actif (KYC validé, non
 * suspendu) et compte utilisateur actif. Suspendre le vendeur ou le compte
 * masque donc immédiatement produits, publications et stories.
 */
export const BOUTIQUE_VISIBLE = {
  statut: 'ACTIVE',
  vendeur: {
    statutVendeur: 'ACTIF',
    utilisateur: { statutCompte: 'ACTIF' },
  },
} as const satisfies Prisma.BoutiqueWhereInput;
