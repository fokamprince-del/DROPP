import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { CreerAdresseDto } from './dto/creer-adresse.dto.js';
import { MiseAJourAdresseDto } from './dto/mise-a-jour-adresse.dto.js';

@Injectable()
export class ClientsService {
  constructor(private readonly prisma: PrismaService) {}

  async obtenirProfil(utilisateurId: string) {
    const client = await this.prisma.client.findUnique({
      where: { id: utilisateurId },
      select: {
        dateCreation: true,
        statutClient: true,
        adresses: {
          orderBy: [
            { estPrincipale: 'desc' },
            { dateCreation: 'desc' },
          ],
        },
      },
    });

    if (!client) {
      throw new NotFoundException('Profil client introuvable.');
    }

    return client;
  }

  async creerAdresse(
    utilisateurId: string,
    dto: CreerAdresseDto,
  ) {
    await this.verifierClient(utilisateurId);

    return this.prisma.$transaction(async (tx) => {
      const nombreAdresses = await tx.adresse.count({
        where: { clientId: utilisateurId },
      });
      const estPrincipale = dto.estPrincipale ?? nombreAdresses === 0;

      if (estPrincipale) {
        await tx.adresse.updateMany({
          where: { clientId: utilisateurId, estPrincipale: true },
          data: { estPrincipale: false },
        });
      }

      return tx.adresse.create({
        data: {
          ...dto,
          clientId: utilisateurId,
          estPrincipale,
        },
      });
    });
  }

  async mettreAJourAdresse(
    utilisateurId: string,
    adresseId: string,
    dto: MiseAJourAdresseDto,
  ) {
    await this.verifierAdresse(utilisateurId, adresseId);

    return this.prisma.$transaction(async (tx) => {
      if (dto.estPrincipale) {
        await tx.adresse.updateMany({
          where: {
            clientId: utilisateurId,
            id: { not: adresseId },
            estPrincipale: true,
          },
          data: { estPrincipale: false },
        });
      }

      return tx.adresse.update({
        where: { id: adresseId },
        data: dto,
      });
    });
  }

  async supprimerAdresse(
    utilisateurId: string,
    adresseId: string,
  ): Promise<void> {
    await this.verifierAdresse(utilisateurId, adresseId);
    await this.prisma.adresse.delete({ where: { id: adresseId } });
  }

  private async verifierClient(utilisateurId: string): Promise<void> {
    const client = await this.prisma.client.findUnique({
      where: { id: utilisateurId },
      select: { id: true },
    });

    if (!client) {
      throw new NotFoundException('Profil client introuvable.');
    }
  }

  private async verifierAdresse(
    utilisateurId: string,
    adresseId: string,
  ): Promise<void> {
    const adresse = await this.prisma.adresse.findFirst({
      where: { id: adresseId, clientId: utilisateurId },
      select: { id: true },
    });

    if (!adresse) {
      throw new NotFoundException('Adresse introuvable.');
    }
  }
}
