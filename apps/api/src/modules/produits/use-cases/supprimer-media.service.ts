import {
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../../infrastructure/stockage/stockage-provider.contract.js';

@Injectable()
export class SupprimerMediaService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(STOCKAGE_PROVIDER)
    private readonly stockage: StockageProvider,
  ) {}

  async executer(
    produitId: string,
    mediaId: string,
    boutiqueId: string,
  ): Promise<void> {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: { boutiqueId: true },
    });
    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId)
      throw new ForbiddenException('Accès refusé.');

    const mediaProduit = await this.prisma.mediaProduit.findUnique({
      where: { produitId_mediaId: { produitId, mediaId } },
      select: { media: { select: { cleStockage: true } } },
    });
    if (!mediaProduit) throw new NotFoundException('Média introuvable.');

    await this.prisma.$transaction([
      this.prisma.mediaProduit.delete({
        where: { produitId_mediaId: { produitId, mediaId } },
      }),
      this.prisma.media.delete({ where: { id: mediaId } }),
    ]);

    await this.stockage
      .supprimer(mediaProduit.media.cleStockage)
      .catch(() => undefined);
  }
}
