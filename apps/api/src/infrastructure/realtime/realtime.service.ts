import { Injectable, Logger } from '@nestjs/common';

import { roomUtilisateur } from './evenements.js';
import { RealtimeGateway } from './realtime.gateway.js';

@Injectable()
export class RealtimeService {
  private readonly logger = new Logger(RealtimeService.name);

  constructor(private readonly gateway: RealtimeGateway) {}

  /** Émet vers tous les appareils connectés des utilisateurs donnés. Ne lève jamais. */
  emettre(utilisateurIds: string | string[], evenement: string, donnees: unknown): void {
    const ids = Array.isArray(utilisateurIds) ? utilisateurIds : [utilisateurIds];
    if (ids.length === 0 || !this.gateway.server) return;
    try {
      this.gateway.server.to(ids.map(roomUtilisateur)).emit(evenement, donnees);
    } catch (erreur) {
      this.logger.warn(`Émission "${evenement}" impossible : ${String(erreur)}`);
    }
  }

  /** Vrai si au moins un appareil de l'utilisateur est connecté (toutes instances). */
  async estEnLigne(utilisateurId: string): Promise<boolean> {
    if (!this.gateway.server) return false;
    try {
      const sockets = await this.gateway.server
        .in(roomUtilisateur(utilisateurId))
        .fetchSockets();
      return sockets.length > 0;
    } catch {
      return false;
    }
  }
}
