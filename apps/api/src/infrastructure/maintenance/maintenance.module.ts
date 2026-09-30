import { Logger, Module, type OnApplicationBootstrap } from '@nestjs/common';
import { BullModule, InjectQueue, Processor, WorkerHost } from '@nestjs/bullmq';
import type { Queue } from 'bullmq';

import { PrismaModule } from '../database/prisma.module.js';
import { StockageModule } from '../stockage/stockage.module.js';
import { NettoyageService } from './nettoyage.service.js';

export const QUEUE_MAINTENANCE = 'maintenance';
const JOB_NETTOYAGE = 'maintenance.nettoyage';

/**
 * Tâches planifiées de l'API. Le planificateur BullMQ est partagé via Redis :
 * avec plusieurs instances, le job ne s'exécute qu'une fois par créneau.
 */
@Processor(QUEUE_MAINTENANCE)
export class MaintenanceProcessor
  extends WorkerHost
  implements OnApplicationBootstrap
{
  private readonly logger = new Logger(MaintenanceProcessor.name);

  constructor(
    private readonly nettoyage: NettoyageService,
    @InjectQueue(QUEUE_MAINTENANCE) private readonly queue: Queue,
  ) {
    super();
  }

  async onApplicationBootstrap(): Promise<void> {
    await this.queue
      .upsertJobScheduler(
        'nettoyage-horaire',
        { every: 60 * 60 * 1000 },
        {
          name: JOB_NETTOYAGE,
          opts: { removeOnComplete: 24, removeOnFail: 50 },
        },
      )
      .catch((e: unknown) =>
        this.logger.error(`Planification du nettoyage : ${String(e)}`),
      );
  }

  async process(): Promise<void> {
    await this.nettoyage.executer();
  }
}

@Module({
  imports: [
    PrismaModule,
    StockageModule,
    BullModule.registerQueue({ name: QUEUE_MAINTENANCE }),
  ],
  providers: [NettoyageService, MaintenanceProcessor],
})
export class MaintenanceModule {}
