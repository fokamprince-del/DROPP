export enum Role {
  ADMIN = 'admin',
  CLIENT = 'client',
  VENDEUR = 'vendeur'
}

export interface UtilisateurAuthentifie {
  utilisateurId: string;
  role: Role;
}