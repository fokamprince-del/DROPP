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
import type { DemanderSignatureDto } from '../dto/demander-signature.dto.js';

const TAILLE_MAX_PAR_TYPE: Record<string, number> = {
  'image/jpeg': 10,
  'image/png': 10,
  'image/webp': 10,
  'video/mp4': 500,
  'video/quicktime': 500,
};

@Injectable()
export class DemanderSignatureMediaService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(STOCKAGE_PROVIDER)
    private readonly stockage: StockageProvider,
  ) {}

  async executer(boutiqueId: string, dto: DemanderSignatureDto) {
    const produit = await this.prisma.produit.findUnique({
      where: { id: dto.produitId },
      select: { boutiqueId: true },
    });
    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId)
      throw new ForbiddenException('Accès refusé.');

    const tailleMax = TAILLE_MAX_PAR_TYPE[dto.typeMime] ?? 10;
    const tailleMo = dto.taille / (1024 * 1024);
    if (tailleMo > tailleMax) {
      throw new BadRequestException(
        `Fichier trop volumineux. Maximum : ${tailleMax} Mo pour ce type.`,
      );
    }

    const typeMedia = dto.typeMime.startsWith('video/') ? 'VIDEO' : 'IMAGE';
    const repertoire = `boutiques/${boutiqueId}/produits/${dto.produitId}/${typeMedia.toLowerCase()}s`;

    const signature = await this.stockage.genererSignatureUpload(
      repertoire,
      dto.typeMime,
      tailleMax,
    );

    return { ...signature, typeMedia };
  }
}
