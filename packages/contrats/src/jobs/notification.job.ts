export const QUEUE_NOTIFICATION = 'notification' as const;

export const JOB_NOTIFICATION = {
  SMS: 'notification.sms',
  EMAIL: 'notification.email',
};

export type JobNotificationSms = {
  numero: string;
  message: string;
};

export type JobNotificationEmail = {
  destinataire: string;
  sujet: string;
  corps: string;
};