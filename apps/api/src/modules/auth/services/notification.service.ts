import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';
import type { Queue } from 'bullmq';

import {
  JOB_NOTIFICATION,
  QUEUE_NOTIFICATION,
  type JobNotificationEmail,
  type JobNotificationSms,
} from '@dropp/contrats';

import type { CanalVerification } from '@dropp/database';

export type MotifOtp =
  | 'inscription'
  | 'connexion'
  | 'reinitialisation'
  | 'verification'
  | 'email';

const LIBELLES: Record<MotifOtp, { sujet: string; action: string }> = {
  inscription: {
    sujet: 'Activez votre compte DROPP',
    action: 'activer votre compte',
  },
  connexion: { sujet: 'Votre code de connexion DROPP', action: 'vous connecter' },
  reinitialisation: {
    sujet: 'Réinitialisation de votre mot de passe DROPP',
    action: 'réinitialiser votre mot de passe',
  },
  verification: {
    sujet: 'Vérifiez votre numéro DROPP',
    action: 'vérifier votre nouveau numéro',
  },
  email: {
    sujet: 'Confirmez votre adresse email DROPP',
    action: 'confirmer votre adresse email',
  },
};

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);
  private readonly dureeMinutes: number;

  constructor(
    @InjectQueue(QUEUE_NOTIFICATION)
    private readonly queue: Queue,
    config: ConfigService,
  ) {
    this.dureeMinutes = Math.round(
      config.getOrThrow<number>('redis.otpTtl') / 60,
    );
  }

  async envoyerOtp(params: {
    destination: string;
    canal: CanalVerification;
    code: string;
    type: MotifOtp;
  }): Promise<void> {
    const { destination, canal, code, type } = params;
    const { sujet, action } = LIBELLES[type];
    const duree = `${this.dureeMinutes} minute${this.dureeMinutes > 1 ? 's' : ''}`;

    try {
      if (canal === 'EMAIL') {
        await this.queue.add(JOB_NOTIFICATION.EMAIL, {
          destinataire: destination,
          sujet,
          corps:
            `Votre code pour ${action} : ${code}\n\n` +
            `Il est valable ${duree}. Ne le communiquez à personne : ` +
            `DROPP ne vous le demandera jamais.\n\n` +
            `Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.`,
          html: gabaritCode({ action, code, duree }),
        } satisfies JobNotificationEmail);
      } else {
        await this.queue.add(JOB_NOTIFICATION.SMS, {
          numero: destination,
          message: `DROPP : ${code} est votre code pour ${action}. Valable ${duree}. Ne le partagez pas.`,
        } satisfies JobNotificationSms);
      }
    } catch (erreur) {
      this.logger.error(`Échec ajout job OTP [${canal}] : ${String(erreur)}`);
    }
  }
}

/** Email HTML minimal, compatible clients mail (styles en ligne, tableau). */
function gabaritCode(p: { action: string; code: string; duree: string }): string {
  return `<!doctype html>
<html lang="fr"><body style="margin:0;padding:0;background:#f4f4f5;font-family:Arial,Helvetica,sans-serif;color:#18181b">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:32px 16px">
<tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#ffffff;border-radius:12px;padding:32px">
<tr><td style="font-size:22px;font-weight:bold;padding-bottom:24px">DROPP</td></tr>
<tr><td style="font-size:16px;line-height:24px;padding-bottom:16px">Voici votre code pour ${p.action} :</td></tr>
<tr><td align="center" style="padding:16px 0 24px">
<div style="display:inline-block;font-size:32px;letter-spacing:8px;font-weight:bold;background:#f4f4f5;border-radius:8px;padding:16px 24px">${p.code}</div>
</td></tr>
<tr><td style="font-size:14px;line-height:22px;color:#52525b">Ce code est valable ${p.duree}. Ne le communiquez à personne : DROPP ne vous le demandera jamais.</td></tr>
<tr><td style="font-size:13px;line-height:20px;color:#a1a1aa;padding-top:24px">Si vous n'êtes pas à l'origine de cette demande, ignorez simplement cet email.</td></tr>
</table>
</td></tr>
</table>
</body></html>`;
}
