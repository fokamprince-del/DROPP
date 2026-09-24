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
} from '../../generated/prisma/client.js';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../infrastructure/stockage/stockage-provider.contract.js';
import type { ConfirmerMediaPublicationDto } from './dto/confirmer-media-publication.dto.js';
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

@Injectable()
export class PublicationsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(STOCKAGE_PROVIDER)
    private readonly stockage: StockageProvider,
  ) {}

  async listerPubliques(page: number, limite: number) {
    const where = {
      statut: StatutPublication.PUBLIEE,
      visibilite: 'PUBLIC' as const,
      boutique: { statut: 'ACTIVE' as const },
    };
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
      donnees: publications.map((publication) => this.presenter(publication)),
      pagination: { total, page, limite, pages: Math.ceil(total / limite) },
    };
  }

  async obtenirPublique(id: string) {
    const publication = await this.prisma.publication.findFirst({
      where: {
        id,
        statut: StatutPublication.PUBLIEE,
        visibilite: 'PUBLIC',
        boutique: { statut: 'ACTIVE' },
      },
      select: publicationSelection,
    });
    if (!publication) throw new NotFoundException('Publication introuvable.');
    return this.presenter(publication);
  }

  async listerMesPublications(utilisateurId: string) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const publications = await this.prisma.publication.findMany({
      where: { boutiqueId: boutique.id },
      select: publicationSelection,
      orderBy: { dateCreation: 'desc' },
    });
    return publications.map((publication) => this.presenter(publication));
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
    await this.obtenirPublicationVendeur(publicationId, boutique.id);
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
    await this.obtenirPublicationVendeur(publicationId, boutique.id);
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
      `boutiques/${boutique.id}/publications/${publicationId}/${typeMedia.toLowerCase()}s`,
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
    const prefixe = `boutiques/${boutique.id}/publications/${publicationId}/`;
    const tailleMax = TAILLE_MAX_PAR_TYPE[dto.typeMime];
    if (
      !dto.cleStockage.startsWith(prefixe) ||
      !tailleMax ||
      dto.taille > tailleMax * 1024 * 1024
    ) {
      throw new BadRequestException('Média invalide pour cette publication.');
    }

    const typeMedia = dto.typeMime.startsWith('video/')
      ? TypeMedia.VIDEO
      : TypeMedia.IMAGE;
    const statutTraitement =
      typeMedia === TypeMedia.IMAGE
        ? StatutTraitementMedia.PRET
        : StatutTraitementMedia.PROCESSING;

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
              taille: dto.taille,
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
      | typeof StatutPublication.PUBLIEE
      | typeof StatutPublication.REJETEE;

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
      select: { id: true },
    });
    if (!publication) throw new NotFoundException('Publication introuvable.');
    return publication;
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

  private presenter(publication: PublicationAvecRelations) {
    return {
      ...publication,
      medias: publication.medias.map(({ media, ...mediaPublication }) => ({
        ...mediaPublication,
        media: {
          id: media.id,
          typeMedia: media.typeMedia,
          typeMime: media.typeMime,
          statutTraitement: media.statutTraitement,
          largeur: media.largeur,
          hauteur: media.hauteur,
          duree: media.duree,
          url: this.stockage.urlPublique(media.cleStockage),
        },
      })),
      likes: publication._count.likes,
      commentaires: publication._count.commentaires,
      _count: undefined,
    };
  }
}
