import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

@Injectable()
export class SessionsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Sessions actives de l'utilisateur ; `actuelle` = celle de cet appareil. */
  async lister(utilisateurId: string, sessionCouranteId?: string) {
    const sessions = await this.prisma.session.findMany({
      where: {
        utilisateurId,
        dateRevocation: null,
        dateExpiration: { gt: new Date() },
      },
      select: {
        id: true,
        methodeAuth: true,
        adresseIpCreation: true,
        dateCreation: true,
        dateDerniereUtilisation: true,
        dateExpiration: true,
        appareil: {
          select: { plateforme: true, modele: true },
        },
      },
      orderBy: { dateCreation: 'desc' },
    });
    return sessions.map((s) => ({ ...s, actuelle: s.id === sessionCouranteId }));
  }
}
