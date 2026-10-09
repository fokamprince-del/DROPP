import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../../infrastructure/stockage/stockage-provider.contract.js';
import { NotificateurService } from '../../notifications/notificateur.service.js';
import { BOUTIQUE_VISIBLE } from '../../shops/boutique-visible.js';

@Injectable()
export class AbonnementService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificateur: NotificateurService,
    @Inject(STOCKAGE_PROVIDER) private readonly stockage: StockageProvider,
  ) {}

  async suivre(utilisateurId: string, vendeurId: string) {
    if (utilisateurId === vendeurId) {
      throw new BadRequestException('Impossible de se suivre soi-même.');
    }

    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: vendeurId },
      select: { statutVendeur: true },
    });

    if (!vendeur || vendeur.statutVendeur !== 'ACTIF') {
      throw new NotFoundException('Vendeur introuvable.');
    }

    const bloque = await this.prisma.blocage.count({
      where: {
        OR: [
          { bloqueurId: utilisateurId, bloqueId: vendeurId },
          { bloqueurId: vendeurId, bloqueId: utilisateurId },
        ],
      },
    });
    if (bloque > 0) throw new NotFoundException('Vendeur introuvable.');

    try {
      await this.prisma.abonnement.create({
        data: { utilisateurId, vendeurId, statut: 'ACTIF' },
      });
    } catch (e: unknown) {
      if (this.estViolationUnicite(e)) {
        throw new ConflictException('Vous suivez déjà ce vendeur.');
      }
      throw e;
    }

    const totalAbonnes = await this.prisma.abonnement.count({
      where: { vendeurId, statut: 'ACTIF' },
    });

    void this.notificateur.nomAffiche(utilisateurId).then((nom) =>
      this.notificateur.notifier({
        utilisateurId: vendeurId,
        type: 'SOCIAL',
        titre: 'Nouvel abonné',
        contenu: `${nom} s’est abonné à votre boutique.`,
        donnees: { utilisateurId },
        cleDedoublonnage: `abonnement:${utilisateurId}:${vendeurId}`,
      }),
    );

    return { vendeurId, abonnes: totalAbonnes };
  }

  /** Boutiques que l'utilisateur suit. */
  async listerMesAbonnements(utilisateurId: string, page: number, limite: number) {
    const where = {
      utilisateurId,
      statut: { not: 'BLOQUE' as const },
      vendeur: { boutique: BOUTIQUE_VISIBLE },
    };
    const [abonnements, total] = await this.prisma.$transaction([
      this.prisma.abonnement.findMany({
        where,
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
        select: {
          dateCreation: true,
          statut: true,
          vendeur: {
            select: {
              boutique: { select: { id: true, nom: true, logoCle: true } },
            },
          },
        },
      }),
      this.prisma.abonnement.count({ where }),
    ]);
    return {
      donnees: abonnements.map((a) => ({
        boutique: a.vendeur.boutique && {
          id: a.vendeur.boutique.id,
          nom: a.vendeur.boutique.nom,
          logoUrl: a.vendeur.boutique.logoCle
            ? this.stockage.urlPublique(a.vendeur.boutique.logoCle, {
                largeur: 200,
                hauteur: 200,
              })
            : null,
        },
        muet: a.statut === 'MUET',
        depuis: a.dateCreation,
      })),
      total,
      page,
      limite,
    };
  }

  /** Abonnés de la boutique du vendeur connecté. */
  async listerMesAbonnes(vendeurId: string, page: number, limite: number) {
    const where = { vendeurId, statut: 'ACTIF' as const };
    const [abonnements, total] = await this.prisma.$transaction([
      this.prisma.abonnement.findMany({
        where,
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
        select: {
          dateCreation: true,
          utilisateur: {
            select: {
              id: true,
              prenom: true,
              nom: true,
              pseudo: true,
              photoProfilCle: true,
            },
          },
        },
      }),
      this.prisma.abonnement.count({ where }),
    ]);
    return {
      donnees: abonnements.map(({ dateCreation, utilisateur }) => {
        const { photoProfilCle, ...u } = utilisateur;
        return {
          ...u,
          photoProfilUrl: photoProfilCle
            ? this.stockage.urlPublique(photoProfilCle, {
                largeur: 100,
                hauteur: 100,
              })
            : null,
          depuis: dateCreation,
        };
      }),
      total,
      page,
      limite,
    };
  }

  private estViolationUnicite(e: unknown): boolean {
    return (
      typeof e === 'object' &&
      e !== null &&
      'code' in e &&
      (e as { code: string }).code === 'P2002'
    );
  }

  async nePlusSuivre(utilisateurId: string, vendeurId: string) {
    const abonnement = await this.prisma.abonnement.findUnique({
      where: {
        utilisateurId_vendeurId: { utilisateurId, vendeurId },
      },
      select: { id: true },
    });

    if (!abonnement) throw new NotFoundException('Abonnement introuvable.');

    await this.prisma.abonnement.delete({
      where: {
        utilisateurId_vendeurId: { utilisateurId, vendeurId },
      },
    });

    const totalAbonnes = await this.prisma.abonnement.count({
      where: { vendeurId, statut: 'ACTIF' },
    });

    return { vendeurId, abonnes: totalAbonnes };
  }
}
