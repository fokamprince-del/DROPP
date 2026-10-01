export const QUEUE_NOTIFICATION = 'notification' as const;

export const JOB_NOTIFICATION = {
  SMS: 'notification.sms',
  EMAIL: 'notification.email',
  PUSH: 'notification.push',
};

export type JobNotificationSms = {
  numero: string;
  message: string;
};

export type JobNotificationEmail = {
  destinataire: string;
  sujet: string;
  /** Version texte (obligatoire : clients mail sans HTML, anti-spam). */
  corps: string;
  /** Version HTML, facultative. */
  html?: string;
};

export type JobNotificationPush = {
  /** Jetons FCM des appareils du destinataire. */
  tokens: string[];
  titre: string;
  corps: string;
  /** Données de navigation transmises à l'app (valeurs string uniquement, contrainte FCM). */
  donnees?: Record<string, string>;
};

/** Valeur de retour du job PUSH : l'API supprime ces jetons expirés. */
export type ResultatNotificationPush = {
  tokensInvalides: string[];
};
