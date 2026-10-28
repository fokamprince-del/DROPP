import { Injectable } from '@nestjs/common';
import { Prisma } from '@dropp/database'; // import de valeur
import { ParametresService } from './parametres.service.js';

@Injectable()
export class CommissionService {
  constructor(private readonly parametres: ParametresService) {}

  /** Taux du vendeur s'il en a un, sinon taux par défaut de la plateforme. */
  async tauxPour(commissionPersonnalisee: Prisma.Decimal | null): Promise<Prisma.Decimal> {
    if (commissionPersonnalisee !== null) return commissionPersonnalisee;
    return new Prisma.Decimal(await this.parametres.lire('commission.taux_defaut'));
  }

  /** commission + net = sous-total, toujours exactement (XAF entiers). */
  calculer(sousTotal: Prisma.Decimal, taux: Prisma.Decimal) {
    const montantCommission = sousTotal
      .mul(taux)
      .toDecimalPlaces(0, Prisma.Decimal.ROUND_HALF_UP);
    return {
      tauxCommission: taux,
      montantCommission,
      montantNetVendeur: sousTotal.minus(montantCommission),
    };
  }
}