export interface SignatureUpload {
  /** URL vers laquelle l'app uploade directement (PUT). */
  uploadUrl: string;
  /** Clé du fichier dans le bucket — à stocker dans Media.cleStockage. */
  cleStockage: string;
  /** Expiration de l'URL signée. */
  expireA: Date;
}

export interface StockageProvider {
  /**
   * Génère une URL signée pour un upload direct depuis le client.
   * @param repertoire  Préfixe du chemin (ex: "produits/uuid-boutique")
   * @param typeMime    Type MIME du fichier (ex: "image/jpeg")
   * @param tailleMo    Taille maximale autorisée en Mo
   */
  genererSignatureUpload(
    repertoire: string,
    typeMime: string,
    tailleMo: number,
  ): Promise<SignatureUpload>;

  /**
   * Retourne l'URL publique d'un fichier stocké.
   * Pour Cloudflare Images : inclut les transformations si précisées.
   */
  urlPublique(cleStockage: string, options?: { largeur?: number; hauteur?: number }): string;

  /**
   * Supprime un fichier du stockage.
   */
  supprimer(cleStockage: string): Promise<void>;
}

export const STOCKAGE_PROVIDER = Symbol('STOCKAGE_PROVIDER');