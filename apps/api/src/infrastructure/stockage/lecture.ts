import {
  estCleePrivee,
  PREFIX_ABONNES,
  type StockageProvider,
} from './stockage-provider.contract.js';

/** Durée de validité des liens de lecture des fichiers privés. */
export const DUREE_LIEN_PRIVE_S = 3600;

/**
 * URL de lecture d'un fichier : publique (cache CDN) si le fichier est public,
 * signée et temporaire s'il est privé (messagerie, contenus réservés aux abonnés).
 */
export async function urlLecture(
  stockage: StockageProvider,
  cleStockage: string,
  options?: { largeur?: number; hauteur?: number },
): Promise<string> {
  return estCleePrivee(cleStockage)
    ? stockage.urlSignee(cleStockage, DUREE_LIEN_PRIVE_S)
    : stockage.urlPublique(cleStockage, options);
}

/** Dossier racine des médias d'un contenu selon sa visibilité. */
export function racineContenu(
  visibilite: 'PUBLIC' | 'ABONNES',
  chemin: string,
): string {
  return visibilite === 'ABONNES' ? `${PREFIX_ABONNES}${chemin}` : chemin;
}

/** Clé équivalente d'un fichier après changement de visibilité. */
export function cleSelonVisibilite(
  cleStockage: string,
  visibilite: 'PUBLIC' | 'ABONNES',
): string {
  const neutre = cleStockage.startsWith(PREFIX_ABONNES)
    ? cleStockage.slice(PREFIX_ABONNES.length)
    : cleStockage;
  return racineContenu(visibilite, neutre);
}
