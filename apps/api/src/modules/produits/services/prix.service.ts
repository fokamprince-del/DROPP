import { Injectable } from '@nestjs/common';
import type { Prisma } from '@dropp/database';

type Decimal = Prisma.Decimal;

@Injectable()
export class PrixService {
  /**
   * Prix final d'une variante : son prix propre si renseigné, sinon prixBase.
   * Règle A validée : le prix variante remplace (ne s'ajoute pas à) prixBase.
   */
  prixVariante(prixVariante: Decimal | null, prixBase: Decimal): Decimal {
    return prixVariante ?? prixBase;
  }

  /**
   * Prix minimum parmi toutes les variantes d'un produit.
   * Utilisé dans le catalogue pour afficher "À partir de X XAF".
   */
  prixMin(
    prixBase: Decimal,
    variantes: Array<{ prix: Decimal | null }>,
  ): Decimal {
    if (variantes.length === 0) return prixBase;
    const prix = variantes.map((v) => this.prixVariante(v.prix, prixBase));
    return prix.reduce((min, p) => (p.lt(min) ? p : min), prix[0]);
  }
}
