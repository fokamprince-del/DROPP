import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  StatutPublication,
  StatutTraitementMedia,
  TypeMedia,
  type Prisma,
  type TypePublication,
  type VisibiliteContenu,
} from '@dropp/database';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { REDIS_CLIENT } from '../../infrastructure/redis/redis.provider.js';
import type { Redis } from 'ioredis';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../infrastructure/stockage/stockage-provider.contract.js';
import { verifierUpload } from '../../infrastructure/stockage/verifier-upload.js';
import {
  cleSelonVisibilite,
  racineContenu,
  urlLecture,
} from '../../infrastructure/stockage/lecture.js';
import {
  filtreVisibilite,
  verifierPublicationVisible,
} from '../interactions/utils/publications.js';
import type { ConfirmerMediaPublicationDto } from './dto/confirmer-media-publication.dto.js';

const MAX_MEDIAS_PAR_PUBLICATION = 10;
import type { CreerPublicationDto } from './dto/creer-publication.dto.js';
import type { DemanderSignaturePublicationDto } from './dto/demander-signature-publication.dto.js';
import type { MiseAJourPublicationDto } from './dto/mise-a-jour-publication.dto.js';

const TAILLE_MAX_PAR_TYPE: Record<string, number> = {
  'image/jpeg': 10,
  'image/png': 10,
  'image/webp': 10,
  'video/mp4': 500,
  'video/quicktime': 500,
};

const publicationSelection = {
  id: true,
  contenu: true,
  type: true,
  visibilite: true,
  statut: true,
  nombreVues: true,
  dateCreation: true,
  dateModification: true,
  boutique: { select: { id: true, nom: true } },
  medias: {
    select: {
      id: true,
      ordre: true,
      media: {
        select: {
          id: true,
          typeMedia: true,
          cleStockage: true,
          typeMime: true,
          statutTraitement: true,
          largeur: true,
          hauteur: true,
          duree: true,
        },
      },
    },
    orderBy: { ordre: 'asc' },
  },
  _count: { select: { likes: true, commentaires: true } },
} as const;

type PublicationAvecRelations = Prisma.PublicationGetPayload<{
  select: typeof publicationSelection;
}>;

const TTL_VUE_S = 24 * 3600;

@Injectable()
export class PublicationsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    @Inject(STOCKAGE_PROVIDER)
    private readonly stockage: StockageProvider,
  ) {}

  /**
   * Fil « Pour toi » : publications publiques uniquement.
   * Page d'une boutique (boutiqueId) : on y ajoute ses publications réservées
   * aux abonnés si l'utilisateur la suit (ou si c'est sa boutique).
   */
  async listerPubliques(
    page: number,
    limite: number,
    boutiqueId?: string,
    utilisateurId?: string,
  ) {
    const where: Prisma.PublicationWhereInput = boutiqueId
      ? { boutiqueId, ...filtreVisibilite(utilisateurId) }
      : {
          statut: StatutPublication.PUBLIEE,
          visibilite: 'PUBLIC' as const,
          boutique: { statut: 'ACTIVE' as const },
        };
    return this.listerAvecFiltre(where, page, limite);
  }

  /**
   * Fil « Abonnements » : publications des boutiques suivies,
   * y compris celles réservées aux abonnés (visibilité ABONNES).
   */
  async listerFilAbonnements(
    utilisateurId: string,
    page: number,
    limite: number,
  ) {
    const where = {
      statut: StatutPublication.PUBLIEE,
      boutique: {
        statut: 'ACTIVE' as const,
        vendeur: {
          abonnements: { some: { utilisateurId, statut: 'ACTIF' as const } },
        },
      },
    };
    return this.listerAvecFiltre(where, page, limite);
  }

  private async listerAvecFiltre(
    where: Prisma.PublicationWhereInput,
    page: number,
    limite: number,
  ) {
    const [publications, total] = await this.prisma.$transaction([
      this.prisma.publication.findMany({
        where,
        select: publicationSelection,
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
      }),
      this.prisma.publication.count({ where }),
    ]);

    return {
      donnees: await Promise.all(publications.map((p) => this.presenter(p))),
      pagination: { total, page, limite, pages: Math.ceil(total / limite) },
    };
  }

  /**
   * Compte une vue : au plus une par spectateur (utilisateur ou IP) et par 24 h,
   * pour que rafraîchir le fil ne gonfle pas le compteur.
   */
  async marquerVue(publicationId: string, spectateur: string) {
    const nouvelle = await this.redis.set(
      `dropp:vue:publication:${publicationId}:${spectateur}`,
      '1',
      'EX',
      TTL_VUE_S,
      'NX',
    );
    if (nouvelle === 'OK') {
      await this.prisma.publication.updateMany({
        where: { id: publicationId, statut: StatutPublication.PUBLIEE },
        data: { nombreVues: { increment: 1 } },
      });
    }
    return { publicationId };
  }

  async obtenirPublique(id: string, utilisateurId?: string) {
    await verifierPublicationVisible(this.prisma, id, utilisateurId);
    const publication = await this.prisma.publication.findUniqueOrThrow({
      where: { id },
      select: publicationSelection,
    });
    return this.presenter(publication);
  }

  async listerMesPublications(utilisateurId: string) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const publications = await this.prisma.publication.findMany({
      where: { boutiqueId: boutique.id },
      select: publicationSelection,
      orderBy: { dateCreation: 'desc' },
    });
    return Promise.all(publications.map((p) => this.presenter(p)));
  }

  async creer(utilisateurId: string, dto: CreerPublicationDto) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const publication = await this.prisma.publication.create({
      data: {
        boutiqueId: boutique.id,
        type: dto.type,
        contenu: dto.contenu,
        visibilite: dto.visibilite,
        statut: StatutPublication.PROCESSING,
      },
      select: publicationSelection,
    });
    return this.presenter(publication);
  }

  async mettreAJour(
    utilisateurId: string,
    publicationId: string,
    dto: MiseAJourPublicationDto,
  ) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const actuelle = await this.obtenirPublicationVendeur(publicationId, boutique.id);
    if (dto.visibilite && dto.visibilite !== actuelle.visibilite) {
      await this.deplacerMedias(publicationId, dto.visibilite);
    }
    const publication = await this.prisma.publication.update({
      where: { id: publicationId },
      data: { ...dto, statut: StatutPublication.PROCESSING },
      select: publicationSelection,
    });
    return this.presenter(publication);
  }

  async supprimer(utilisateurId: string, publicationId: string): Promise<void> {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    await this.obtenirPublicationVendeur(publicationId, boutique.id);
    await this.prisma.publication.update({
      where: { id: publicationId },
      data: { statut: StatutPublication.SUPPRIMEE },
    });
  }

  async demanderSignature(
    utilisateurId: string,
    publicationId: string,
    dto: DemanderSignaturePublicationDto,
  ) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const pub = await this.obtenirPublicationVendeur(publicationId, boutique.id);
    const tailleMax = TAILLE_MAX_PAR_TYPE[dto.typeMime];
    if (!tailleMax || dto.taille > tailleMax * 1024 * 1024) {
      throw new BadRequestException(
        'Fichier trop volumineux ou non pris en charge.',
      );
    }
    const typeMedia = dto.typeMime.startsWith('video/')
      ? TypeMedia.VIDEO
      : TypeMedia.IMAGE;
    const signature = await this.stockage.genererSignatureUpload(
      `${this.dossierMedias(boutique.id, publicationId, pub.visibilite)}/${typeMedia.toLowerCase()}s`,
      dto.typeMime,
      tailleMax,
    );
    return { ...signature, typeMedia };
  }

  async confirmerMedia(
    utilisateurId: string,
    publicationId: string,
    dto: ConfirmerMediaPublicationDto,
  ) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const publication = await this.obtenirPublicationVendeur(
      publicationId,
      boutique.id,
    );
    const tailleMax = TAILLE_MAX_PAR_TYPE[dto.typeMime];
    if (!tailleMax) {
      throw new BadRequestException('Type de fichier non pris en charge.');
    }
    const nombreMedias = await this.prisma.mediaPublication.count({
      where: { publicationId },
    });
    if (nombreMedias >= MAX_MEDIAS_PAR_PUBLICATION) {
      throw new BadRequestException(
        `Maximum ${MAX_MEDIAS_PAR_PUBLICATION} médias par publication.`,
      );
    }
    const reel = await verifierUpload(this.stockage, {
      cleStockage: dto.cleStockage,
      prefixe: this.dossierMedias(boutique.id, publicationId, publication.visibilite),
      tailleMaxMo: tailleMax,
      typesMime: [dto.typeMime],
    });

    const typeMedia = dto.typeMime.startsWith('video/')
      ? TypeMedia.VIDEO
      : TypeMedia.IMAGE;
    // Pas de transcodage : vidéos MP4/MOV lues directement depuis R2.
    const statutTraitement = StatutTraitementMedia.PRET;

    const media = await this.prisma.$transaction(async (tx) => {
      const dernierMedia = await tx.mediaPublication.findFirst({
        where: { publicationId },
        orderBy: { ordre: 'desc' },
        select: { ordre: true },
      });
      return tx.mediaPublication.create({
        data: {
          publication: { connect: { id: publicationId } },
          ordre: (dernierMedia?.ordre ?? -1) + 1,
          media: {
            create: {
              typeMedia,
              cleStockage: dto.cleStockage,
              typeMime: dto.typeMime,
              taille: reel.taille,
              largeur: dto.largeur,
              hauteur: dto.hauteur,
              duree: dto.duree,
              statutTraitement,
            },
          },
        },
        select: { media: { select: { id: true, statutTraitement: true } } },
      });
    });

    return { publicationId: publication.id, ...media.media };
  }

  async moderer(publicationId: string, statut: StatutPublication) {
    if (
      statut !== StatutPublication.PUBLIEE &&
      statut !== StatutPublication.REJETEE
    ) {
      throw new BadRequestException('Statut de modération invalide.');
    }
    const statutModere = statut as
      typeof StatutPublication.PUBLIEE | typeof StatutPublication.REJETEE;

    const publication = await this.prisma.publication.findUnique({
      where: { id: publicationId },
      select: {
        type: true,
        medias: {
          select: {
            media: { select: { typeMedia: true, statutTraitement: true } },
          },
        },
      },
    });
    if (!publication) throw new NotFoundException('Publication introuvable.');
    if (statutModere === StatutPublication.PUBLIEE) {
      this.verifierMediasPublication(publication.type, publication.medias);
    }

    const resultat = await this.prisma.publication.update({
      where: { id: publicationId },
      data: { statut: statutModere },
      select: publicationSelection,
    });
    return this.presenter(resultat);
  }

  private async obtenirBoutiqueActive(utilisateurId: string) {
    const boutique = await this.prisma.boutique.findUnique({
      where: { id: utilisateurId },
      select: { id: true, statut: true },
    });
    if (!boutique) throw new NotFoundException('Boutique introuvable.');
    if (boutique.statut !== 'ACTIVE') {
      throw new ForbiddenException('Boutique inactive.');
    }
    return boutique;
  }

  private async obtenirPublicationVendeur(
    publicationId: string,
    boutiqueId: string,
  ) {
    const publication = await this.prisma.publication.findFirst({
      where: {
        id: publicationId,
        boutiqueId,
        statut: { not: StatutPublication.SUPPRIMEE },
      },
      select: { id: true, visibilite: true },
    });
    if (!publication) throw new NotFoundException('Publication introuvable.');
    return publication;
  }

  /** Dossier des médias : sous abonnes/ (bucket privé) si réservé aux abonnés. */
  private dossierMedias(
    boutiqueId: string,
    publicationId: string,
    visibilite: VisibiliteContenu,
  ) {
    return racineContenu(visibilite, `boutiques/${boutiqueId}/publications/${publicationId}`);
  }

  /**
   * Changement de visibilité : les fichiers passent du bucket public au privé
   * (ou l'inverse), pour qu'un lien partagé ne donne plus accès au contenu.
   */
  private async deplacerMedias(publicationId: string, visibilite: VisibiliteContenu) {
    const liens = await this.prisma.mediaPublication.findMany({
      where: { publicationId },
      select: { media: { select: { id: true, cleStockage: true } } },
    });
    for (const { media } of liens) {
      const nouvelle = cleSelonVisibilite(media.cleStockage, visibilite);
      if (nouvelle === media.cleStockage) continue;
      await this.stockage.deplacer(media.cleStockage, nouvelle);
      await this.prisma.media.update({
        where: { id: media.id },
        data: { cleStockage: nouvelle },
      });
    }
  }

  private verifierMediasPublication(
    type: TypePublication,
    medias: Array<{
      media: { typeMedia: TypeMedia; statutTraitement: StatutTraitementMedia };
    }>,
  ): void {
    if (
      medias.length === 0 ||
      medias.some(
        ({ media }) => media.statutTraitement !== StatutTraitementMedia.PRET,
      )
    ) {
      throw new BadRequestException(
        'Tous les médias doivent être prêts avant publication.',
      );
    }
    if (
      type === 'IMAGE' &&
      (medias.length !== 1 || medias[0].media.typeMedia !== TypeMedia.IMAGE)
    ) {
      throw new BadRequestException(
        'Une publication image requiert une image unique.',
      );
    }
    if (
      type === 'VIDEO' &&
      (medias.length !== 1 || medias[0].media.typeMedia !== TypeMedia.VIDEO)
    ) {
      throw new BadRequestException(
        'Une publication vidéo requiert une vidéo unique.',
      );
    }
    if (type === 'CARROUSEL' && (medias.length < 2 || medias.length > 10)) {
      throw new BadRequestException(
        'Un carrousel requiert entre 2 et 10 médias.',
      );
    }
  }

  private async presenter(publication: PublicationAvecRelations) {
    const urls = await Promise.all(
      publication.medias.map(({ media }) => urlLecture(this.stockage, media.cleStockage)),
    );
    return {
      ...publication,
      medias: publication.medias.map(({ media, ...mediaPublication }, i) => ({
        ...mediaPublication,
        media: {
          id: media.id,
          typeMedia: media.typeMedia,
          typeMime: media.typeMime,
          statutTraitement: media.statutTraitement,
          largeur: media.largeur,
          hauteur: media.hauteur,
          duree: media.duree,
          url: urls[i],
        },
      })),
      likes: publication._count.likes,
      commentaires: publication._count.commentaires,
      _count: undefined,
    };
  }
}
