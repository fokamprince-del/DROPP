export interface SignatureUpload {
  /** URL vers laquelle l'app uploade directement (PUT). */
  uploadUrl: string;
  /** Clé du fichier dans le bucket — à renvoyer à la confirmation. */
  cleStockage: string;
  /** Expiration de l'URL signée. */
  expireA: Date;
  /**
   * En-têtes que l'app DOIT envoyer avec le PUT (ils font partie de la
   * signature : un Content-Type différent est rejeté par R2 avec un 403).
   */
  enTetes: Record<string, string>;
}

/** Ce que le stockage sait réellement d'un fichier uploadé. */
export interface MetadonneesFichier {
  taille: number;
  typeMime: string | null;
}

export interface StockageProvider {
  /**
   * Génère une URL signée pour un upload direct depuis le client.
   * @param repertoire  Préfixe du chemin (ex: "boutiques/uuid/produits/uuid/images")
   * @param typeMime    Type MIME du fichier (ex: "image/jpeg")
   * @param tailleMo    Taille maximale autorisée en Mo (contrôlée à la confirmation)
   */
  genererSignatureUpload(
    repertoire: string,
    typeMime: string,
    tailleMo: number,
  ): Promise<SignatureUpload>;

  /**
   * Retourne l'URL publique d'un fichier stocké.
   * largeur/hauteur : redimensionnement à la volée (images uniquement,
   * si les transformations Cloudflare sont activées).
   */
  urlPublique(
    cleStockage: string,
    options?: { largeur?: number; hauteur?: number },
  ): string;

  /** Supprime un fichier du stockage (sans erreur s'il n'existe pas). */
  supprimer(cleStockage: string): Promise<void>;

  /** Métadonnées réelles du fichier (HeadObject), null s'il n'a pas été uploadé. */
  metadonnees(cleStockage: string): Promise<MetadonneesFichier | null>;

  /**
   * URL de lecture temporaire (signée) — pour les fichiers privés
   * (pièces jointes de messagerie), qui n'ont pas d'URL publique.
   */
  urlSignee(cleStockage: string, dureeSecondes?: number): Promise<string>;

  /**
   * Signale qu'un upload a été confirmé et rattaché en base : il ne sera pas
   * supprimé par le nettoyage des uploads abandonnés.
   */
  marquerUtilise?(cleStockage: string): Promise<void>;

  /**
   * Déplace un fichier vers une nouvelle clé (copie puis suppression).
   * Sert quand un contenu change de visibilité : public ⇄ réservé aux abonnés.
   */
  deplacer(source: string, destination: string): Promise<void>;
}

/**
 * Préfixes stockés dans le bucket privé (jamais d'URL publique, lus par URL signée) :
 * - conversations/ : pièces jointes de messagerie ;
 * - abonnes/       : médias des publications et stories réservées aux abonnés.
 */
export const PREFIX_ABONNES = 'abonnes/';
export const PREFIXES_PRIVES = ['conversations/', PREFIX_ABONNES] as const;

export const estCleePrivee = (cleStockage: string) =>
  PREFIXES_PRIVES.some((p) => cleStockage.startsWith(p));

export const STOCKAGE_PROVIDER = Symbol('STOCKAGE_PROVIDER');
