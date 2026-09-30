import { Logger } from '@nestjs/common';
import { Processor, WorkerHost } from '@nestjs/bullmq';
import type { Job } from 'bullmq';

import {
  JOB_COMMANDE,
  QUEUE_COMMANDE,
  type JobExpirationPassage,
} from '@dropp/contrats';

import { CommandeService } from './commande.service.js';

/**
 * Traité dans l'API (et non dans apps/worker) car il a besoin de Prisma.
 * Le job est idempotent : sans effet si la commande a été payée ou annulée.
 */
@Processor(QUEUE_COMMANDE)
export class CommandeExpirationProcessor extends WorkerHost {
  private readonly logger = new Logger(CommandeExpirationProcessor.name);

  constructor(private readonly commandes: CommandeService) {
    super();
  }

  async process(job: Job): Promise<void> {
    if (job.name !== JOB_COMMANDE.EXPIRATION_PASSAGE) {
      this.logger.warn(`Job inconnu : ${job.name}`);
      return;
    }
    const { passageCommandeId } = job.data as JobExpirationPassage;
    await this.commandes.expirer(passageCommandeId);
  }
}
