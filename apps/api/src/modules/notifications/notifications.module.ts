import { Global, Module } from '@nestjs/common';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { QueueModule } from '../../infrastructure/queue/queue.module.js';
import { NotificateurService } from './notificateur.service.js';
import { NotificationsController } from './notifications.controller.js';
import { NotificationsService } from './notifications.service.js';
import { PushRetourListener } from './push-retour.listener.js';

/** Global : NotificateurService injectable par tous les modules métier. */
@Global()
@Module({
  imports: [PrismaModule, QueueModule],
  controllers: [NotificationsController],
  providers: [NotificateurService, NotificationsService, PushRetourListener],
  exports: [NotificateurService],
})
export class NotificationsModule {}
