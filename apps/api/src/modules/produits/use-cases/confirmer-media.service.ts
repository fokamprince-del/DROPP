import {
  BadRequestException,
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
import { verifierUpload } from '../../../infrastructure/stockage/verifier-upload.js';
import { PublicationAutoService } from '../services/publication-auto.service.js';
import type { ConfirmerMediaDto } from '../dto/confirmer-media.dto.js';

const MAX_MEDIAS_PAR_PRODUIT = 10;
const TAILLE_MAX_MO = { IMAGE: 10, VIDEO: 500 } as const;

@Injectable()
export class ConfirmerMediaService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly publicationAuto: PublicationAutoService,
    @Inject(STOCKAGE_PROVIDER)
    private readonly stockage: StockageProvider,
  ) {}

  async executer(boutiqueId: string, dto: ConfirmerMediaDto) {
    const produit = await this.prisma.produit.findUnique({
      where: { id: dto.produitId },
      select: { boutiqueId: true },
    });
    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId)
      throw new ForbiddenException('Accès refusé.');

    const nombreMedias = await this.prisma.mediaProduit.count({
      where: { produitId: dto.produitId },
    });
    if (nombreMedias >= MAX_MEDIAS_PAR_PRODUIT) {
      throw new BadRequestException(
        `Maximum ${MAX_MEDIAS_PAR_PRODUIT} médias par produit.`,
      );
    }

    const typeMedia = dto.typeMime.startsWith('video/') ? 'VIDEO' : 'IMAGE';

    // La clé doit venir d'une signature émise pour CE produit de CETTE boutique,
    // et le fichier réel doit respecter les limites (taille déclarée non fiable).
    const reel = await verifierUpload(this.stockage, {
      cleStockage: dto.cleStockage,
      prefixe: `boutiques/${boutiqueId}/produits/${dto.produitId}/`,
      tailleMaxMo: TAILLE_MAX_MO[typeMedia],
      typesMime: [dto.typeMime],
    });

    // Pas de transcodage : les images sont redimensionnées à la volée par
    // Cloudflare, les vidéos MP4/MOV sont lues directement depuis R2.
    const statutTraitement = 'PRET';

    const media = await this.prisma.$transaction(async (tx) => {
      const nouveauMedia = await tx.media.create({
        data: {
          typeMedia,
          cleStockage: dto.cleStockage,
          typeMime: dto.typeMime,
          taille: reel.taille,
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

    await this.publicationAuto.tenter(dto.produitId);

    return media;
  }
}
