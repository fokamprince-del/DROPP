export interface NotificationProvider {
  envoyerSms(numero: string, message: string): Promise<void>;
  envoyerEmail(destinataire: string, sujet: string, corps: string): Promise<void>;
}

export const NOTIFICATION_PROVIDER = Symbol('NOTIFICATION_PROVIDER');