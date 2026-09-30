import { Injectable, NotFoundException } from '@nestjs/common';

import { TypeNotification } from '../../generated/prisma/enums.js';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { EVENEMENT } from '../../infrastructure/realtime/evenements.js';
import { RealtimeService } from '../../infrastructure/realtime/realtime.service.js';
import type { EnregistrerAppareilDto } from './dto/enregistrer-appareil.dto.js';
import type { ModifierPreferencesDto } from './dto/modifier-preferences.dto.js';

/**
 * Types que l'utilisateur peut couper. COMMANDE, PAIEMENT, SYSTEME et SECURITE
 * sont transactionnels : toujours envoyés.
 */
export const TYPES_CONFIGURABLES = [
  TypeNotification.MESSAGE,
  TypeNotification.SOCIAL,
  TypeNotification.PROMOTION,
] as const;

const notificationSelection = {
  id: true,
  type: true,
  titre: true,
  contenu: true,
  donnees: true,
  estLu: true,
  dateCreation: true,
  dateLecture: true,
} as const;

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeService,
  ) {}

  async lister(
    utilisateurId: string,
    page: number,
    limite: number,
    nonLuesSeulement: boolean,
  ) {
    const where = {
      utilisateurId,
      ...(nonLuesSeulement && { estLu: false }),
    };
    const [donnees, total, nonLues] = await this.prisma.$transaction([
      this.prisma.notification.findMany({
        where,
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
        select: notificationSelection,
      }),
      this.prisma.notification.count({ where }),
      this.prisma.notification.count({
        where: { utilisateurId, estLu: false },
      }),
    ]);
    return { donnees, total, nonLues, page, limite };
  }

  async compteur(utilisateurId: string) {
    const nonLues = await this.prisma.notification.count({
      where: { utilisateurId, estLu: false },
    });
    return { nonLues };
  }

  async marquerLue(utilisateurId: string, id: string) {
    const resultat = await this.prisma.notification.updateMany({
      where: { id, utilisateurId, estLu: false },
      data: { estLu: true, dateLecture: new Date() },
    });
    if (resultat.count === 0) {
      const existe = await this.prisma.notification.count({
        where: { id, utilisateurId },
      });
      if (!existe) throw new NotFoundException('Notification introuvable.');
    }
    return this.publierCompteur(utilisateurId);
  }

  async toutLire(utilisateurId: string) {
    await this.prisma.notification.updateMany({
      where: { utilisateurId, estLu: false },
      data: { estLu: true, dateLecture: new Date() },
    });
    return this.publierCompteur(utilisateurId);
  }

  async supprimer(utilisateurId: string, id: string): Promise<void> {
    const resultat = await this.prisma.notification.deleteMany({
      where: { id, utilisateurId },
    });
    if (resultat.count === 0) {
      throw new NotFoundException('Notification introuvable.');
    }
    await this.publierCompteur(utilisateurId);
  }

  // ── Préférences ───────────────────────────────────────────────────────────

  async listerPreferences(utilisateurId: string) {
    const existantes = await this.prisma.preferenceNotification.findMany({
      where: { utilisateurId },
      select: { type: true, active: true },
    });
    const parType = new Map(existantes.map((p) => [p.type, p.active]));
    // Absence de ligne = activé par défaut.
    return TYPES_CONFIGURABLES.map((type) => ({
      type,
      active: parType.get(type) ?? true,
    }));
  }

  async modifierPreferences(utilisateurId: string, dto: ModifierPreferencesDto) {
    await this.prisma.$transaction(
      dto.preferences.map((p) =>
        this.prisma.preferenceNotification.upsert({
          where: { utilisateurId_type: { utilisateurId, type: p.type } },
          create: { utilisateurId, type: p.type, active: p.active },
          update: { active: p.active },
        }),
      ),
    );
    return this.listerPreferences(utilisateurId);
  }

  // ── Appareils (jetons FCM) ────────────────────────────────────────────────

  /**
   * Upsert par jeton : si un autre compte se connecte sur le même téléphone,
   * le jeton lui est réattribué (l'ancien compte ne reçoit plus ses push ici).
   */
  async enregistrerAppareil(utilisateurId: string, dto: EnregistrerAppareilDto) {
    return this.prisma.appareil.upsert({
      where: { tokenFcm: dto.tokenFcm },
      create: {
        utilisateurId,
        tokenFcm: dto.tokenFcm,
        plateforme: dto.plateforme,
        modele: dto.modele,
      },
      update: {
        utilisateurId,
        plateforme: dto.plateforme,
        modele: dto.modele,
        derniereUtilisation: new Date(),
      },
      select: { id: true, plateforme: true, modele: true, dateCreation: true },
    });
  }

  /** À appeler à la déconnexion pour ne plus recevoir de push sur cet appareil. */
  async retirerAppareil(utilisateurId: string, tokenFcm: string): Promise<void> {
    await this.prisma.appareil.deleteMany({
      where: { utilisateurId, tokenFcm },
    });
  }

  private async publierCompteur(utilisateurId: string) {
    const compteur = await this.compteur(utilisateurId);
    this.realtime.emettre(
      utilisateurId,
      EVENEMENT.NOTIFICATIONS_COMPTEUR,
      compteur,
    );
    return compteur;
  }
}
