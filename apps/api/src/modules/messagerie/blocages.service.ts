import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../infrastructure/stockage/stockage-provider.contract.js';
import {
  estViolationUnicite,
  presenterProfil,
  profilPublicSelection,
} from './presentation.js';

@Injectable()
export class BlocagesService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(STOCKAGE_PROVIDER) private readonly stockage: StockageProvider,
  ) {}

  /** Vrai si l'un des deux a bloqué l'autre. */
  async estBloque(a: string, b: string): Promise<boolean> {
    const n = await this.prisma.blocage.count({
      where: {
        OR: [
          { bloqueurId: a, bloqueId: b },
          { bloqueurId: b, bloqueId: a },
        ],
      },
    });
    return n > 0;
  }

  async bloquer(utilisateurId: string, cibleId: string) {
    if (utilisateurId === cibleId) {
      throw new BadRequestException('Impossible de se bloquer soi-même.');
    }
    const cible = await this.prisma.utilisateur.findUnique({
      where: { id: cibleId },
      select: { id: true },
    });
    if (!cible) throw new NotFoundException('Utilisateur introuvable.');

    try {
      await this.prisma.$transaction([
        this.prisma.blocage.create({
          data: { bloqueurId: utilisateurId, bloqueId: cibleId },
        }),
        // Bloquer rompt aussi les abonnements dans les deux sens.
        this.prisma.abonnement.deleteMany({
          where: {
            OR: [
              { utilisateurId, vendeurId: cibleId },
              { utilisateurId: cibleId, vendeurId: utilisateurId },
            ],
          },
        }),
      ]);
    } catch (e) {
      if (estViolationUnicite(e)) {
        throw new ConflictException('Utilisateur déjà bloqué.');
      }
      throw e;
    }
    return { utilisateurId: cibleId, bloque: true };
  }

  async debloquer(utilisateurId: string, cibleId: string) {
    const { count } = await this.prisma.blocage.deleteMany({
      where: { bloqueurId: utilisateurId, bloqueId: cibleId },
    });
    if (count === 0) throw new NotFoundException('Blocage introuvable.');
    return { utilisateurId: cibleId, bloque: false };
  }

  async lister(utilisateurId: string) {
    const blocages = await this.prisma.blocage.findMany({
      where: { bloqueurId: utilisateurId },
      orderBy: { dateCreation: 'desc' },
      select: {
        dateCreation: true,
        bloque: { select: profilPublicSelection },
      },
    });
    return blocages.map((b) => ({
      ...presenterProfil(this.stockage, b.bloque),
      dateBlocage: b.dateCreation,
    }));
  }
}
