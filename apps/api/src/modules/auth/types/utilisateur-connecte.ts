export interface UtilisateurConnecte {
  id: string;
  statutCompte: string;
  telephoneVerifie: boolean;
  /** Session ayant émis le jeton (absente des jetons émis avant son ajout). */
  sessionId?: string;
}
