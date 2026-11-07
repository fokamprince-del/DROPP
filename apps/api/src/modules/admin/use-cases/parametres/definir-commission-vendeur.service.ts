// definir-commission-vendeur.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import { ParametresService } from '../../../parametres/parametres.service.js';
import type { CommissionVendeurDto, DefinirCommissionVendeurDto } from '../../dto/parametres.dto.js';

@Injectable()
export class DefinirCommissionVendeurService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly parametres: ParametresService,
  ) {}

  async executer(
    vendeurId: string,
    adminId: string,
    dto: DefinirCommissionVendeurDto,
  ): Promise<CommissionVendeurDto> {
    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: vendeurId },
      select: { commissionPersonnalisee: true },
    });
    if (!vendeur) throw new NotFoundException('Vendeur introuvable.');

    await this.prisma.$transaction([
      this.prisma.vendeur.update({
        where: { id: vendeurId },
        data: { commissionPersonnalisee: dto.taux },
      }),
      this.prisma.journalAudit.create({
        data: {
          administrateurId: adminId,
          action: 'DEFINIR_COMMISSION_VENDEUR',
          resourceType: 'Vendeur',
          resourceId: vendeurId,
          details: {
            ancienne: vendeur.commissionPersonnalisee?.toString() ?? null,
            nouvelle: dto.taux,
            raison: dto.raison,
          },
        },
      }),
    ]);

    return {
      vendeurId,
      commissionPersonnalisee: dto.taux,
      tauxEffectif: dto.taux ?? (await this.parametres.lire('commission.taux_defaut')),
    };
  }
}