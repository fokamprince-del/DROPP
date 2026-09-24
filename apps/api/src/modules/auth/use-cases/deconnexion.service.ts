import { Injectable } from '@nestjs/common';
import { JetonService } from '../services/jeton.service.js';

@Injectable()
export class DeconnexionService {
  constructor(private readonly jetonService: JetonService) {}

  /** Révoque la session courante (déconnexion simple). */
  async executer(sessionId: string, utilisateurId: string): Promise<void> {
    await this.jetonService.revoquerSession(sessionId, utilisateurId);
  }

  /** Révoque toutes les sessions (déconnexion partout). */
  async deconnecterPartout(utilisateurId: string): Promise<void> {
    await this.jetonService.revoquerToutesLesSessions(utilisateurId);
  }
}
