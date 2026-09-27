import { Injectable, NotFoundException } from '@nestjs/common';
import { StatutPublication } from '@dropp/database';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';

@Injectable()
export class LikesService {
  constructor(private readonly prisma: PrismaService) {}

  async aimer(utilisateurId: string, publicationId: string) {
    await this.verifierPublicationVisible(publicationId);
    await this.prisma.aime.upsert({
      where: {
        utilisateurId_publicationId: { utilisateurId, publicationId },
      },
      create: { utilisateurId, publicationId },
      update: {},
    });
    return { aime: true };
  }

  async retirer(utilisateurId: string, publicationId: string): Promise<void> {
    await this.prisma.aime.deleteMany({
      where: { utilisateurId, publicationId },
    });
  }

  async obtenirEtat(utilisateurId: string, publicationId: string) {
    await this.verifierPublicationVisible(publicationId);
    const [aime, total] = await this.prisma.$transaction([
      this.prisma.aime.findUnique({
        where: {
          utilisateurId_publicationId: { utilisateurId, publicationId },
        },
        select: { id: true },
      }),
      this.prisma.aime.count({ where: { publicationId } }),
    ]);
    return { aime: Boolean(aime), total };
  }

  async compter(publicationId: string) {
    await this.verifierPublicationVisible(publicationId);
    return {
      total: await this.prisma.aime.count({ where: { publicationId } }),
    };
  }

  private async verifierPublicationVisible(
    publicationId: string,
  ): Promise<void> {
    const publication = await this.prisma.publication.findFirst({
      where: {
        id: publicationId,
        statut: StatutPublication.PUBLIEE,
        visibilite: 'PUBLIC',
        boutique: { statut: 'ACTIVE' },
      },
      select: { id: true },
    });
    if (!publication) throw new NotFoundException('Publication introuvable.');
  }
}
