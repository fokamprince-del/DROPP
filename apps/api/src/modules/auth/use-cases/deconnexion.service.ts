import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { JetonService } from '../services/jeton.service.js';

@Injectable()
export class DeconnexionService {
  constructor(
    private readonly jetonService: JetonService,
    private readonly prisma: PrismaService,
  ) {}

  /** Révoque une session (la session courante pour une déconnexion simple). */
  async executer(sessionId: string | undefined, utilisateurId: string): Promise<void> {
    if (!sessionId) return;
    await this.jetonService.revoquerSession(sessionId, utilisateurId);
    await this.journaliser(utilisateurId, 'SESSION_REVOQUEE', { sessionId });
  }

  /** Révoque toutes les sessions (déconnexion partout). */
  async deconnecterPartout(utilisateurId: string): Promise<void> {
    await this.jetonService.revoquerToutesLesSessions(utilisateurId);
    await this.journaliser(utilisateurId, 'TOUTES_SESSIONS_REVOQUEES');
  }

  private journaliser(
    utilisateurId: string,
    evenement: 'SESSION_REVOQUEE' | 'TOUTES_SESSIONS_REVOQUEES',
    details?: { sessionId: string },
  ) {
    return this.prisma.journalSecurite
      .create({ data: { utilisateurId, evenement, details } })
      .catch(() => undefined);
  }
}
