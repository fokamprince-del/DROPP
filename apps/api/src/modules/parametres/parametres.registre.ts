export type DefinitionParametre = {
  description: string;
  type: 'taux' | 'entier';
  min: number;
  max: number;
  defaut: number;
};

export const PARAMETRES = {
  'commission.taux_defaut': {
    description: 'Commission DROPP appliquée aux vendeurs sans taux personnalisé (0,10 = 10 %).',
    type: 'taux',
    min: 0,
    max: 0.5,
    defaut: 0.1, // PLACEHOLDER à valider
  },
  'sequestre.delai_liberation_jours': {
    description: 'Jours entre la livraison et la libération du séquestre au vendeur.',
    type: 'entier',
    min: 0,
    max: 60,
    defaut: 7, // PLACEHOLDER à valider
  },
  'stock.duree_reservation_minutes': {
    description: 'Durée de réservation du stock pendant le paiement.',
    type: 'entier',
    min: 5,
    max: 120,
    defaut: 15,
  },
} as const satisfies Record<string, DefinitionParametre>;

export type CleParametre = keyof typeof PARAMETRES;

/** Plafond d'une commission personnalisée : même borne que le taux par défaut. */
export const COMMISSION_MAX = PARAMETRES['commission.taux_defaut'].max;

export function estCleParametre(cle: string): cle is CleParametre {
  return Object.hasOwn(PARAMETRES, cle);
}

/** Retourne un message d'erreur, ou null si la valeur est valide. */
export function erreurValeur(cle: CleParametre, valeur: number): string | null {
  const d: DefinitionParametre = PARAMETRES[cle];
  if (!Number.isFinite(valeur)) return 'La valeur doit être un nombre.';
  if (valeur < d.min || valeur > d.max) {
    return `La valeur doit être comprise entre ${d.min} et ${d.max}.`;
  }
  if (d.type === 'entier' && !Number.isInteger(valeur)) return 'La valeur doit être un entier.';
  if (d.type === 'taux' && Number(valeur.toFixed(4)) !== valeur) {
    return 'Un taux accepte au plus 4 décimales.';
  }
  return null;
}

/** Vue d'un paramètre : `brut` est la valeur en base (ou undefined = défaut). */
export function resoudre(cle: CleParametre, brut: unknown) {
  const d: DefinitionParametre = PARAMETRES[cle];
  const personnalise = typeof brut === 'number';
  return {
    cle,
    description: d.description,
    type: d.type,
    valeur: personnalise ? brut : d.defaut,
    valeurParDefaut: d.defaut,
    min: d.min,
    max: d.max,
    personnalise,
  };
}