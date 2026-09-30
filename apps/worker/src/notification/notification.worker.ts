import { Inject, Logger } from '@nestjs/common';
import { Processor, WorkerHost } from '@nestjs/bullmq';
import type { Job } from 'bullmq';

import {
  JOB_NOTIFICATION,
  QUEUE_NOTIFICATION,
  type JobNotificationEmail,
  type JobNotificationPush,
  type JobNotificationSms,
  type ResultatNotificationPush,
} from '@dropp/contrats';

import {
  SMS_PROVIDER,
  type SmsProvider,
} from './providers/sms/sms.contract.js';
import {
  EMAIL_PROVIDER,
  type EmailProvider,
} from './providers/email/email.contract.js';
import {
  PUSH_PROVIDER,
  type PushProvider,
} from './providers/push/push.contract.js';

@Processor(QUEUE_NOTIFICATION)
export class NotificationWorker extends WorkerHost {
  private readonly logger = new Logger(NotificationWorker.name);

  constructor(
    @Inject(SMS_PROVIDER) private readonly sms: SmsProvider,
    @Inject(EMAIL_PROVIDER) private readonly email: EmailProvider,
    @Inject(PUSH_PROVIDER) private readonly push: PushProvider,
  ) {
    super();
  }

  async process(job: Job): Promise<ResultatNotificationPush | void> {
    switch (job.name) {
      case JOB_NOTIFICATION.SMS:
        await this.traiterSms(job as Job<JobNotificationSms>);
        break;
      case JOB_NOTIFICATION.EMAIL:
        await this.traiterEmail(job as Job<JobNotificationEmail>);
        break;
      case JOB_NOTIFICATION.PUSH:
        // La valeur de retour est lue par l'API (QueueEvents) pour purger les jetons morts.
        return this.traiterPush(job as Job<JobNotificationPush>);
      default:
        this.logger.warn(`Job inconnu : ${job.name}`);
    }
  }

  private async traiterSms(job: Job<JobNotificationSms>): Promise<void> {
    this.logger.log(`SMS → ${job.data.numero}`);
    await this.sms.envoyer(job.data.numero, job.data.message);
  }

  private async traiterEmail(job: Job<JobNotificationEmail>): Promise<void> {
    this.logger.log(`Email → ${job.data.destinataire}`);
    await this.email.envoyer(
      job.data.destinataire,
      job.data.sujet,
      job.data.corps,
      job.data.html,
    );
  }

  private async traiterPush(
    job: Job<JobNotificationPush>,
  ): Promise<ResultatNotificationPush> {
    if (job.data.tokens.length === 0) return { tokensInvalides: [] };
    this.logger.log(`Push → ${job.data.tokens.length} appareil(s)`);
    return this.push.envoyer(job.data);
  }
}
