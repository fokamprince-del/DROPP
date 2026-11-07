export interface MessagePush {
  tokens: string[];
  titre: string;
  corps: string;
  donnees?: Record<string, string>;
}

export interface PushProvider {
  /** Envoie la notification et retourne les jetons à supprimer (expirés/invalides). */
  envoyer(message: MessagePush): Promise<{ tokensInvalides: string[] }>;
}

export const PUSH_PROVIDER = Symbol('PUSH_PROVIDER');
