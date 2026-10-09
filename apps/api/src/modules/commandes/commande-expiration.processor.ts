import { Logger, type OnApplicationBootstrap } from '@nestjs/common';
import { InjectQueue, Processor, WorkerHost } from '@nestjs/bullmq';
import type { Job, Queue } from 'bullmq';

import {
  JOB_COMMANDE,
  QUEUE_COMMANDE,
  type JobExpirationPassage,
} from '@dropp/contrats';

import { CommandeService } from './commande.service.js';

/**
 * Traité dans l'API (et non dans apps/worker) car il a besoin de Prisma.
 * Les jobs sont idempotents : sans effet si la commande a été payée ou annulée.
 */
@Processor(QUEUE_COMMANDE)
export class CommandeExpirationProcessor
  extends WorkerHost
  implements OnApplicationBootstrap
{
  private readonly logger = new Logger(CommandeExpirationProcessor.name);

  constructor(
    private readonly commandes: CommandeService,
    @InjectQueue(QUEUE_COMMANDE) private readonly queue: Queue,
  ) {
    super();
  }

  /** Balayage toutes les 5 min, partagé entre instances (planificateur BullMQ). */
  async onApplicationBootstrap(): Promise<void> {
    await this.queue
      .upsertJobScheduler(
        'balayage-expirations',
        { every: 5 * 60_000 },
        {
          name: JOB_COMMANDE.BALAYAGE_EXPIRATIONS,
          opts: { removeOnComplete: 24, removeOnFail: 50 },
        },
      )
      .catch((e: unknown) =>
        this.logger.error(`Planification du balayage : ${String(e)}`),
      );
  }

  async process(job: Job): Promise<void> {
    switch (job.name) {
      case JOB_COMMANDE.EXPIRATION_PASSAGE: {
        const { passageCommandeId } = job.data as JobExpirationPassage;
        await this.commandes.expirer(passageCommandeId);
        return;
      }
      case JOB_COMMANDE.BALAYAGE_EXPIRATIONS: {
        const n = await this.commandes.expirerEnRetard();
        if (n > 0) this.logger.warn(`${n} commande(s) expirée(s) par le balayage.`);
        return;
      }
      default:
        this.logger.warn(`Job inconnu : ${job.name}`);
    }
  }
}
