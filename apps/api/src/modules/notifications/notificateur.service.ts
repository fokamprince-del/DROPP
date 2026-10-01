import { Inject, Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import type { Queue } from 'bullmq';
import type { Redis } from 'ioredis';

import {
  JOB_NOTIFICATION,
  QUEUE_NOTIFICATION,
  type JobNotificationPush,
} from '@dropp/contrats';

import type { TypeNotification } from '@dropp/database';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { EVENEMENT } from '../../infrastructure/realtime/evenements.js';
import { RealtimeService } from '../../infrastructure/realtime/realtime.service.js';
import { REDIS_CLIENT } from '../../infrastructure/redis/redis.provider.js';

export interface NouvelleNotification {
  utilisateurId: string;
  type: TypeNotification;
  titre: string;
  contenu: string;
  /** Données de navigation (ex: { publicationId }) — valeurs string (contrainte FCM). */
  donnees?: Record<string, string>;
  /**
   * false = push + temps réel uniquement, sans ligne dans la liste des notifications
   * (cas des messages : ils ont déjà leur propre écran).
   */
  persister?: boolean;
  /**
   * Évite le spam (like/unlike répété…) : une seule notification par clé
   * pendant 24 h.
   */
  cleDedoublonnage?: string;
}

const TTL_DEDOUBLONNAGE_S = 24 * 3600;

/**
 * Point d'entrée unique pour notifier un utilisateur.
 * Ne lève jamais : une notification ratée ne doit pas faire échouer
 * l'action métier qui la déclenche (like, commande…).
 */
@Injectable()
export class NotificateurService {
  private readonly logger = new Logger(NotificateurService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeService,
    @InjectQueue(QUEUE_NOTIFICATION) private readonly queue: Queue,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  async notifier(notification: NouvelleNotification): Promise<void> {
    try {
      await this.traiter(notification);
    } catch (erreur) {
      this.logger.error(
        `Notification ${notification.type} → ${notification.utilisateurId} : ${String(erreur)}`,
      );
    }
  }

  /** Nom affiché d'un utilisateur dans une notification (boutique si vendeur). Ne lève jamais. */
  async nomAffiche(utilisateurId: string): Promise<string> {
    try {
      const u = await this.prisma.utilisateur.findUnique({
        where: { id: utilisateurId },
        select: {
          prenom: true,
          nom: true,
          vendeur: { select: { boutique: { select: { nom: true } } } },
        },
      });
      if (u) return u.vendeur?.boutique?.nom ?? `${u.prenom} ${u.nom}`.trim();
    } catch (erreur) {
      this.logger.warn(`Nom de ${utilisateurId} introuvable : ${String(erreur)}`);
    }
    return 'Quelqu’un';
  }

  private async traiter(n: NouvelleNotification): Promise<void> {
    if (n.cleDedoublonnage) {
      const nouveau = await this.redis.set(
        `dropp:notif:dedup:${n.cleDedoublonnage}`,
        '1',
        'EX',
        TTL_DEDOUBLONNAGE_S,
        'NX',
      );
      if (nouveau !== 'OK') return;
    }

    const donnees: Record<string, string> = { ...n.donnees, type: n.type };

    if (n.persister !== false) {
      const creee = await this.prisma.notification.create({
        data: {
          utilisateurId: n.utilisateurId,
          type: n.type,
          titre: n.titre,
          contenu: n.contenu,
          donnees: n.donnees ?? undefined,
        },
        select: {
          id: true,
          type: true,
          titre: true,
          contenu: true,
          donnees: true,
          estLu: true,
          dateCreation: true,
        },
      });
      donnees.notificationId = creee.id;
      this.realtime.emettre(
        n.utilisateurId,
        EVENEMENT.NOTIFICATION_NOUVELLE,
        creee,
      );
    }

    // La préférence coupe le push, pas la notification in-app.
    const preference = await this.prisma.preferenceNotification.findUnique({
      where: {
        utilisateurId_type: { utilisateurId: n.utilisateurId, type: n.type },
      },
      select: { active: true },
    });
    if (preference && !preference.active) return;

    const appareils = await this.prisma.appareil.findMany({
      where: { utilisateurId: n.utilisateurId },
      select: { tokenFcm: true },
    });
    if (appareils.length === 0) return;

    await this.queue.add(JOB_NOTIFICATION.PUSH, {
      tokens: appareils.map((a) => a.tokenFcm),
      titre: n.titre,
      corps: n.contenu,
      donnees,
    } satisfies JobNotificationPush);
  }
}
