import { Module } from '@nestjs/common';
import { SmsModule } from './providers/sms/sms.module.js';
import { EmailModule } from './providers/email/email.module.js';
import { PushModule } from './providers/push/push.module.js';
import { NotificationWorker } from './notification.worker.js';
import { QUEUE_NOTIFICATION } from '@dropp/contrats';
import { BullModule } from '@nestjs/bullmq';

@Module({
  imports: [
    BullModule.registerQueue({ name: QUEUE_NOTIFICATION }),
    SmsModule,
    EmailModule,
    PushModule,
  ],
  providers: [NotificationWorker],
})
export class NotificationModule {}
