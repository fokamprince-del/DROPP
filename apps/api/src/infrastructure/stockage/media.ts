/** Formats acceptés pour les médias de contenu (produits, publications, stories). */
export const TYPES_MIME_MEDIA = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'video/mp4',
  'video/quicktime',
] as const;

/** Taille maximale en Mo par type. */
export const TAILLE_MAX_MEDIA_MO: Record<(typeof TYPES_MIME_MEDIA)[number], number> = {
  'image/jpeg': 10,
  'image/png': 10,
  'image/webp': 10,
  'video/mp4': 500,
  'video/quicktime': 500,
};

export const TAILLE_MAX_MEDIA_OCTETS = 500 * 1024 * 1024;

/** Bornes des métadonnées déclarées par l'app. */
export const DIMENSION_MAX_PX = 10_000;
export const DUREE_MAX_S = 3_600;
