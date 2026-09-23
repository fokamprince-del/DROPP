import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { AjusterStockDto } from '../dto/ajuster-stock.dto.js';

@Injectable()
export class AjusterStockService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(
    produitId: string,
    varianteId: string,
    boutiqueId: string,
    dto: AjusterStockDto,
  ) {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: { boutiqueId: true },
    });
    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId)
      throw new ForbiddenException('Accès refusé.');

    const resultat = await this.prisma.$queryRaw<
      { stock_disponible: number }[]
    >`
      UPDATE variantes_produits
      SET stock_disponible = stock_disponible + ${dto.delta}
      WHERE id = ${varianteId}::uuid
        AND produit_id = ${produitId}::uuid
        AND stock_disponible + ${dto.delta} >= 0
      RETURNING stock_disponible
    `;

    if (resultat.length === 0) {
      throw new BadRequestException('Stock insuffisant pour cette opération.');
    }

    return { stockDisponible: resultat[0].stock_disponible };
  }
}
