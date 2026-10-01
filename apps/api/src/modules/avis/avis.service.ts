import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import type { Prisma } from '@dropp/database';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../infrastructure/stockage/stockage-provider.contract.js';
import { NotificateurService } from '../notifications/notificateur.service.js';
import type { CreerAvisDto, ModifierAvisDto } from './dto/avis.dto.js';

/** Un avis peut être modifié / supprimé pendant 30 jours. */
const DELAI_MODIFICATION_MS = 30 * 24 * 3_600_000;

const avisSelection = {
  id: true,
  note: true,
  commentaire: true,
  dateCreation: true,
  utilisateur: {
    select: { id: true, prenom: true, pseudo: true, photoProfilCle: true },
  },
  ligneSousCommande: {
    select: { produitId: true, nomProduitSnapshot: true, varianteSnapshot: true },
  },
} as const;

type AvisBrut = Prisma.AvisGetPayload<{ select: typeof avisSelection }>;

@Injectable()
export class AvisService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificateur: NotificateurService,
    @Inject(STOCKAGE_PROVIDER) private readonly stockage: StockageProvider,
  ) {}

  async creer(utilisateurId: string, dto: CreerAvisDto) {
    const ligne = await this.prisma.ligneSousCommande.findUnique({
      where: { id: dto.ligneSousCommandeId },
      select: {
        produitId: true,
        nomProduitSnapshot: true,
        avis: { select: { id: true } },
        articleCommande: {
          select: {
            statut: true,
            vendeurId: true,
            commande: { select: { utilisateurId: true } },
          },
        },
      },
    });
    if (!ligne || ligne.articleCommande.commande.utilisateurId !== utilisateurId) {
      throw new NotFoundException('Article introuvable dans vos commandes.');
    }
    if (ligne.articleCommande.statut !== 'LIVREE') {
      throw new ForbiddenException(
        'Vous pourrez donner votre avis une fois la commande livrée.',
      );
    }
    if (ligne.avis) {
      throw new ConflictException('Vous avez déjà donné votre avis sur cet article.');
    }

    const avis = await this.prisma.avis.create({
      data: {
        utilisateurId,
        ligneSousCommandeId: dto.ligneSousCommandeId,
        note: dto.note,
        commentaire: dto.commentaire,
      },
      select: avisSelection,
    });

    void this.notificateur.notifier({
      utilisateurId: ligne.articleCommande.vendeurId,
      type: 'SOCIAL',
      titre: `Nouvel avis ${'★'.repeat(dto.note)}${'☆'.repeat(5 - dto.note)}`,
      contenu: `Un client a noté « ${ligne.nomProduitSnapshot} ».`,
      donnees: { avisId: avis.id, ...(ligne.produitId && { produitId: ligne.produitId }) },
    });

    return this.presenter(avis);
  }

  async modifier(utilisateurId: string, avisId: string, dto: ModifierAvisDto) {
    await this.avisModifiable(utilisateurId, avisId);
    const avis = await this.prisma.avis.update({
      where: { id: avisId },
      data: { note: dto.note, commentaire: dto.commentaire },
      select: avisSelection,
    });
    return this.presenter(avis);
  }

  async supprimer(utilisateurId: string, avisId: string): Promise<void> {
    await this.avisModifiable(utilisateurId, avisId);
    await this.prisma.avis.delete({ where: { id: avisId } });
  }

  /** Avis publics d'un produit + résumé (moyenne, répartition des notes). */
  async listerPourProduit(produitId: string, page: number, limite: number) {
    const where = { ligneSousCommande: { produitId } };
    const [avis, resume] = await Promise.all([
      this.prisma.avis.findMany({
        where,
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
        select: avisSelection,
      }),
      this.resume(where),
    ]);
    return { resume, donnees: avis.map((a) => this.presenter(a)), page, limite };
  }

  /** Note globale d'une boutique (tous ses produits). */
  resumeBoutique(boutiqueId: string) {
    return this.resume({ ligneSousCommande: { articleCommande: { vendeurId: boutiqueId } } });
  }

  /** Articles livrés que l'utilisateur n'a pas encore notés. */
  async aNoter(utilisateurId: string) {
    const lignes = await this.prisma.ligneSousCommande.findMany({
      where: {
        avis: null,
        articleCommande: { statut: 'LIVREE', commande: { utilisateurId } },
      },
      orderBy: { articleCommande: { dateCreation: 'desc' } },
      take: 50,
      select: {
        id: true,
        produitId: true,
        nomProduitSnapshot: true,
        varianteSnapshot: true,
        articleCommande: { select: { commandeId: true, dateCreation: true } },
      },
    });
    return lignes.map((l) => ({
      ligneSousCommandeId: l.id,
      produitId: l.produitId,
      nomProduit: l.nomProduitSnapshot,
      variante: l.varianteSnapshot,
      commandeId: l.articleCommande.commandeId,
      dateCommande: l.articleCommande.dateCreation,
    }));
  }

  private async resume(where: Prisma.AvisWhereInput) {
    const [agregat, groupes] = await Promise.all([
      this.prisma.avis.aggregate({ where, _avg: { note: true }, _count: { _all: true } }),
      this.prisma.avis.groupBy({ by: ['note'], where, _count: { _all: true } }),
    ]);
    const repartition: Record<string, number> = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    for (const g of groupes) repartition[g.note] = g._count._all;
    return {
      moyenne: agregat._avg.note ? Math.round(agregat._avg.note * 10) / 10 : null,
      total: agregat._count._all,
      repartition,
    };
  }

  private async avisModifiable(utilisateurId: string, avisId: string) {
    const avis = await this.prisma.avis.findUnique({
      where: { id: avisId },
      select: { utilisateurId: true, dateCreation: true },
    });
    if (!avis || avis.utilisateurId !== utilisateurId) {
      throw new NotFoundException('Avis introuvable.');
    }
    if (Date.now() - avis.dateCreation.getTime() > DELAI_MODIFICATION_MS) {
      throw new ForbiddenException('Cet avis ne peut plus être modifié.');
    }
  }

  private presenter(a: AvisBrut) {
    const { photoProfilCle, ...auteur } = a.utilisateur;
    return {
      id: a.id,
      note: a.note,
      commentaire: a.commentaire,
      dateCreation: a.dateCreation,
      // Nom de famille masqué : avis publics.
      auteur: {
        ...auteur,
        photoProfilUrl: photoProfilCle
          ? this.stockage.urlPublique(photoProfilCle, { largeur: 100, hauteur: 100 })
          : null,
      },
      produitId: a.ligneSousCommande.produitId,
      variante: a.ligneSousCommande.varianteSnapshot,
    };
  }
}
