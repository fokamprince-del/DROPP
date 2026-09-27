export interface EmailProvider {
  envoyer(destinataire: string, sujet: string, corps: string): Promise<void>;
}

export const EMAIL_PROVIDER = Symbol('EMAIL_PROVIDER');
