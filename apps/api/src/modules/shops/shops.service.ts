import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import {
  TAILLE_MAX_IMAGE_MO,
  TYPES_MIME_IMAGE,
  type SignatureImageDto,
} from '../../infrastructure/stockage/image.dto.js';
import { verifierUpload } from '../../infrastructure/stockage/verifier-upload.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../infrastructure/stockage/stockage-provider.contract.js';
import { EnregistrerBoutiqueDto } from './dto/enregistrer-boutique.dto.js';
import { MiseAJourBoutiqueDto } from './dto/mise-a-jour-boutique.dto.js';
import { BOUTIQUE_VISIBLE } from './boutique-visible.js';

export type TypeImageBoutique = 'logo' | 'banniere';

const boutiqueSelection = {
  id: true,
  nom: true,
  description: true,
  biographie: true,
  logoCle: true,
  banniereCle: true,
  statut: true,
  dateCreation: true,
  dateModification: true,
} as const;

type BoutiqueBrute = {
  logoCle: string | null;
  banniereCle: string | null;
} & Record<string, unknown>;

@Injectable()
export class ShopsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(STOCKAGE_PROVIDER) private readonly stockage: StockageProvider,
  ) {}

  async obtenirMaBoutique(vendeurId: string) {
    const boutique = await this.prisma.boutique.findUnique({
      where: { id: vendeurId },
      select: boutiqueSelection,
    });

    if (!boutique) {
      throw new NotFoundException('Boutique introuvable.');
    }

    return this.presenter(boutique);
  }

  /** Recherche de boutiques actives par nom (les plus suivies d'abord). */
  async rechercher(q: string | undefined, page: number, limite: number) {
    const where = {
      ...BOUTIQUE_VISIBLE,
      ...(q && { nom: { contains: q, mode: 'insensitive' as const } }),
    };
    const [boutiques, total] = await this.prisma.$transaction([
      this.prisma.boutique.findMany({
        where,
        orderBy: [
          { vendeur: { abonnements: { _count: 'desc' } } },
          { dateCreation: 'desc' },
        ],
        skip: (page - 1) * limite,
        take: limite,
        select: {
          id: true,
          nom: true,
          description: true,
          logoCle: true,
          banniereCle: true,
          quartier: true,
          ville: true,
          vendeur: {
            select: {
              _count: {
                select: { abonnements: { where: { statut: 'ACTIF' } } },
              },
            },
          },
        },
      }),
      this.prisma.boutique.count({ where }),
    ]);
    return {
      donnees: boutiques.map(({ vendeur, ...b }) => ({
        ...this.presenter(b),
        abonnes: vendeur._count.abonnements,
      })),
      total,
      page,
      limite,
    };
  }

  /** Page publique d'une boutique (profil + compteurs + état d'abonnement). */
  async obtenirPublique(boutiqueId: string, utilisateurId?: string) {
    const boutique = await this.prisma.boutique.findFirst({
      where: { id: boutiqueId, ...BOUTIQUE_VISIBLE },
      select: {
        id: true,
        nom: true,
        description: true,
        biographie: true,
        quartier: true,
        ville: true,
        logoCle: true,
        banniereCle: true,
        dateCreation: true,
      },
    });
    if (!boutique) {
      throw new NotFoundException('Boutique introuvable.');
    }

    const [abonnes, produits, publications, abonnement] = await Promise.all([
      this.prisma.abonnement.count({
        where: { vendeurId: boutiqueId, statut: 'ACTIF' },
      }),
      this.prisma.produit.count({
        where: { boutiqueId, statut: 'PUBLIE' },
      }),
      this.prisma.publication.count({
        where: { boutiqueId, statut: 'PUBLIEE' },
      }),
      utilisateurId
        ? this.prisma.abonnement.findUnique({
            where: {
              utilisateurId_vendeurId: { utilisateurId, vendeurId: boutiqueId },
            },
            select: { statut: true },
          })
        : null,
    ]);

    return {
      ...this.presenter(boutique),
      statistiques: { abonnes, produits, publications },
      estAbonne: abonnement?.statut === 'ACTIF',
      estMaBoutique: utilisateurId === boutiqueId,
    };
  }

  async creerBoutique(vendeurId: string, dto: EnregistrerBoutiqueDto) {
    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: vendeurId },
      select: {
        id: true,
        statutVendeur: true,
        boutique: { select: { id: true } },
      },
    });

    if (!vendeur) {
      throw new NotFoundException('Profil vendeur introuvable.');
    }

    if (vendeur.statutVendeur !== 'ACTIF') {
      throw new ForbiddenException(
        'La validation KYC est requise avant de créer une boutique.',
      );
    }

    if (vendeur.boutique) {
      throw new ConflictException('Ce vendeur possède déjà une boutique.');
    }

    // Le vendeur est déjà validé (KYC) : la boutique est visible tout de suite.
    // Sa suspension passe par celle du vendeur (voir BOUTIQUE_VISIBLE).
    const boutique = await this.prisma.boutique.create({
      data: { id: vendeurId, ...dto, statut: 'ACTIVE' },
      select: boutiqueSelection,
    });
    return this.presenter(boutique);
  }

  async mettreAJourMaBoutique(vendeurId: string, dto: MiseAJourBoutiqueDto) {
    try {
      const boutique = await this.prisma.boutique.update({
        where: { id: vendeurId },
        data: dto,
        select: boutiqueSelection,
      });
      return this.presenter(boutique);
    } catch (error: unknown) {
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        error.code === 'P2025'
      ) {
        throw new NotFoundException('Boutique introuvable.');
      }

      throw error;
    }
  }

  // ── Logo / bannière ───────────────────────────────────────────────────────

  async signatureImage(
    vendeurId: string,
    type: TypeImageBoutique,
    dto: SignatureImageDto,
  ) {
    await this.obtenirMaBoutique(vendeurId);
    return this.stockage.genererSignatureUpload(
      this.repertoire(vendeurId, type),
      dto.typeMime,
      TAILLE_MAX_IMAGE_MO,
    );
  }

  async confirmerImage(
    vendeurId: string,
    type: TypeImageBoutique,
    cleStockage: string,
  ) {
    await verifierUpload(this.stockage, {
      cleStockage,
      prefixe: this.repertoire(vendeurId, type),
      tailleMaxMo: TAILLE_MAX_IMAGE_MO,
      typesMime: TYPES_MIME_IMAGE,
    });
    return this.remplacerImage(vendeurId, type, cleStockage);
  }

  supprimerImage(vendeurId: string, type: TypeImageBoutique) {
    return this.remplacerImage(vendeurId, type, null);
  }

  private async remplacerImage(
    vendeurId: string,
    type: TypeImageBoutique,
    cle: string | null,
  ) {
    const avant = await this.prisma.boutique.findUnique({
      where: { id: vendeurId },
      select: { logoCle: true, banniereCle: true },
    });
    if (!avant) throw new NotFoundException('Boutique introuvable.');

    const champ = type === 'logo' ? 'logoCle' : 'banniereCle';
    const boutique = await this.prisma.boutique.update({
      where: { id: vendeurId },
      data: { [champ]: cle },
      select: boutiqueSelection,
    });

    const ancienne = avant[champ];
    if (ancienne && ancienne !== cle) {
      await this.stockage.supprimer(ancienne).catch(() => undefined);
    }
    return this.presenter(boutique);
  }

  private repertoire(vendeurId: string, type: TypeImageBoutique) {
    return `boutiques/${vendeurId}/${type}`;
  }

  private presenter<T extends BoutiqueBrute>(boutique: T) {
    const { logoCle, banniereCle, ...reste } = boutique;
    return {
      ...reste,
      logoUrl: logoCle
        ? this.stockage.urlPublique(logoCle, { largeur: 400, hauteur: 400 })
        : null,
      banniereUrl: banniereCle
        ? this.stockage.urlPublique(banniereCle, { largeur: 1500 })
        : null,
    };
  }
}
