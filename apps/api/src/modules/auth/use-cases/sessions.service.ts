import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

@Injectable()
export class SessionsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Liste les sessions actives de l'utilisateur connecté. */
  async lister(utilisateurId: string) {
    return this.prisma.session.findMany({
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
  }
}
