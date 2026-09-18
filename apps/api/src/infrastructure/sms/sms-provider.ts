export const SMS_PROVIDER = Symbol('SMS_PROVIDER');

export interface SmsProvider {
  envoyerCodeVerification(
    numeroTelephone: string,
    code: string,
  ): Promise<void>;
}