import type { StockageProvider } from '../../infrastructure/stockage/stockage-provider.contract.js';

/** Sélection Prisma du profil public d'un participant. */
export const profilPublicSelection = {
  id: true,
  prenom: true,
  nom: true,
  pseudo: true,
  photoProfilCle: true,
  vendeur: {
    select: {
      boutique: { select: { id: true, nom: true, logoCle: true } },
    },
  },
} as const;

export interface ProfilPublicBrut {
  id: string;
  prenom: string;
  nom: string;
  pseudo: string | null;
  photoProfilCle: string | null;
  vendeur: {
    boutique: { id: string; nom: string; logoCle: string | null } | null;
  } | null;
}

export function presenterProfil(
  stockage: StockageProvider,
  u: ProfilPublicBrut,
) {
  const boutique = u.vendeur?.boutique;
  return {
    id: u.id,
    prenom: u.prenom,
    nom: u.nom,
    pseudo: u.pseudo,
    photoProfilUrl: u.photoProfilCle
      ? stockage.urlPublique(u.photoProfilCle, { largeur: 200, hauteur: 200 })
      : null,
    boutique: boutique
      ? {
          id: boutique.id,
          nom: boutique.nom,
          logoUrl: boutique.logoCle
            ? stockage.urlPublique(boutique.logoCle, {
                largeur: 200,
                hauteur: 200,
              })
            : null,
        }
      : null,
  };
}

/** Nom affiché d'un expéditeur : la boutique si c'est un vendeur. */
export function nomAffiche(u: ProfilPublicBrut): string {
  return u.vendeur?.boutique?.nom ?? `${u.prenom} ${u.nom}`.trim();
}

export function estViolationUnicite(e: unknown): boolean {
  return (
    typeof e === 'object' &&
    e !== null &&
    'code' in e &&
    (e as { code: string }).code === 'P2002'
  );
}
