import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { PartagerDto } from '../dto/partager.dto.js';
import { verifierPublicationVisible } from '../utils/publications.js';

@Injectable()
export class PartagerPublicationService {
  private readonly appScheme: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.appScheme = config.getOrThrow<string>('app.deepLinkScheme');
  }

  async executer(
    utilisateurId: string,
    publicationId: string,
    dto: PartagerDto,
  ) {
    await verifierPublicationVisible(this.prisma, publicationId);

    // Enregistrement du partage (comptabilisation)
    await this.prisma.partage.upsert({
      where: {
        utilisateurId_publicationId: { utilisateurId, publicationId },
      },
      create: { utilisateurId, publicationId },
      update: {}, // On ne duplique pas, on upsert
    });

    const totalPartages = await this.prisma.partage.count({
      where: { publicationId },
    });

    // Génération du lien profond
    const lienProfond = `${this.appScheme}://publications/${publicationId}`;

    return {
      publicationId,
      lienProfond,
      plateforme: dto.plateforme,
      partages: totalPartages,
    };
  }
}
