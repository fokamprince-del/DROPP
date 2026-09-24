import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { PublicationAutoService } from '../services/publication-auto.service.js';
import type { ConfirmerMediaDto } from '../dto/confirmer-media.dto.js';

@Injectable()
export class ConfirmerMediaService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly publicationAuto: PublicationAutoService,
  ) {}

  async executer(boutiqueId: string, dto: ConfirmerMediaDto) {
    const produit = await this.prisma.produit.findUnique({
      where: { id: dto.produitId },
      select: { boutiqueId: true },
    });
    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId)
      throw new ForbiddenException('Accès refusé.');

    const typeMedia = dto.typeMime.startsWith('video/') ? 'VIDEO' : 'IMAGE';
    // Images : PRET immédiatement (Cloudflare Images transforme à la volée).
    // Vidéos : PROCESSING (worker de transcodage à brancher plus tard).
    const statutTraitement = typeMedia === 'IMAGE' ? 'PRET' : 'PROCESSING';

    const media = await this.prisma.$transaction(async (tx) => {
      const nouveauMedia = await tx.media.create({
        data: {
          typeMedia,
          cleStockage: dto.cleStockage,
          typeMime: dto.typeMime,
          taille: dto.taille,
          statutTraitement,
        },
        select: { id: true, typeMedia: true, statutTraitement: true },
      });

      const dernierOrdre = await tx.mediaProduit.findFirst({
        where: { produitId: dto.produitId },
        orderBy: { ordre: 'desc' },
        select: { ordre: true },
      });

      await tx.mediaProduit.create({
        data: {
          produitId: dto.produitId,
          mediaId: nouveauMedia.id,
          ordre: (dernierOrdre?.ordre ?? -1) + 1,
        },
      });

      return nouveauMedia;
    });

    if (statutTraitement === 'PRET') {
      await this.publicationAuto.tenter(dto.produitId);
    }

    return media;
  }
}
