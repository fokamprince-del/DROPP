import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import {
  StatutPublication,
  StatutTraitementMedia,
  TypeMedia,
  type Prisma,
} from '../../generated/prisma/client.js';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../infrastructure/stockage/stockage-provider.contract.js';
import type { ConfirmerStoryDto } from './dto/confirmer-story.dto.js';
import type { CreerStoryDto } from './dto/creer-story.dto.js';

const TAILLE_MAX_PAR_TYPE: Record<string, number> = {
  'image/jpeg': 10,
  'image/png': 10,
  'image/webp': 10,
  'video/mp4': 500,
  'video/quicktime': 500,
};

const storySelection = {
  id: true,
  visibilite: true,
  statut: true,
  ordreCreation: true,
  dateCreation: true,
  dateExpiration: true,
  boutique: { select: { id: true, nom: true } },
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
} as const;

type StoryAvecRelations = Prisma.StoryGetPayload<{
  select: typeof storySelection;
}>;

@Injectable()
export class StoriesService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(STOCKAGE_PROVIDER)
    private readonly stockage: StockageProvider,
  ) {}

  async listerPubliques(page: number, limite: number) {
    const stories = await this.prisma.story.findMany({
      where: {
        statut: StatutPublication.PUBLIEE,
        visibilite: 'PUBLIC',
        dateExpiration: { gt: new Date() },
        boutique: { statut: 'ACTIVE' },
      },
      select: storySelection,
      orderBy: { dateCreation: 'desc' },
      skip: (page - 1) * limite,
      take: limite,
    });
    return stories.map((story) => this.presenter(story));
  }

  async listerMesStories(utilisateurId: string) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const stories = await this.prisma.story.findMany({
      where: { boutiqueId: boutique.id },
      select: storySelection,
      orderBy: { dateCreation: 'desc' },
    });
    return stories.map((story) => this.presenter(story));
  }

  async creer(utilisateurId: string, dto: CreerStoryDto) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    if (dto.dateExpiration <= new Date()) {
      throw new BadRequestException('La date d’expiration doit être future.');
    }
    const tailleMax = TAILLE_MAX_PAR_TYPE[dto.typeMime];
    if (!tailleMax || dto.taille > tailleMax * 1024 * 1024) {
      throw new BadRequestException(
        'Fichier trop volumineux ou non pris en charge.',
      );
    }
    const typeMedia = dto.typeMime.startsWith('video/')
      ? TypeMedia.VIDEO
      : TypeMedia.IMAGE;
    const storyId = randomUUID();
    const signature = await this.stockage.genererSignatureUpload(
      `boutiques/${boutique.id}/stories/${storyId}/${typeMedia.toLowerCase()}s`,
      dto.typeMime,
      tailleMax,
    );

    const story = await this.prisma.story.create({
      data: {
        id: storyId,
        boutique: { connect: { id: boutique.id } },
        visibilite: dto.visibilite,
        statut: StatutPublication.PROCESSING,
        dateExpiration: dto.dateExpiration,
        media: {
          create: {
            typeMedia,
            cleStockage: signature.cleStockage,
            typeMime: dto.typeMime,
            taille: dto.taille,
            statutTraitement: StatutTraitementMedia.PROCESSING,
          },
        },
      },
      select: storySelection,
    });

    return { story: this.presenter(story), signature, typeMedia };
  }

  async confirmer(
    utilisateurId: string,
    storyId: string,
    dto: ConfirmerStoryDto,
  ) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const storyExistante = await this.obtenirStoryVendeur(storyId, boutique.id);
    const prefixe = `boutiques/${boutique.id}/stories/${storyId}/`;
    const tailleMax = TAILLE_MAX_PAR_TYPE[dto.typeMime];
    if (
      !dto.cleStockage.startsWith(prefixe) ||
      !tailleMax ||
      dto.taille > tailleMax * 1024 * 1024
    ) {
      throw new BadRequestException('Média invalide pour cette story.');
    }

    const typeMedia = dto.typeMime.startsWith('video/')
      ? TypeMedia.VIDEO
      : TypeMedia.IMAGE;
    const statutTraitement =
      typeMedia === TypeMedia.IMAGE
        ? StatutTraitementMedia.PRET
        : StatutTraitementMedia.PROCESSING;

    const story = await this.prisma.$transaction(async (tx) => {
      await tx.media.update({
        where: { id: storyExistante.mediaId },
        data: {
          typeMedia,
          cleStockage: dto.cleStockage,
          typeMime: dto.typeMime,
          taille: dto.taille,
          largeur: dto.largeur,
          hauteur: dto.hauteur,
          duree: dto.duree,
          statutTraitement,
        },
      });
      return tx.story.update({
        where: { id: storyId },
        data: {
          statut:
            statutTraitement === StatutTraitementMedia.PRET
              ? StatutPublication.PUBLIEE
              : StatutPublication.PROCESSING,
        },
        select: storySelection,
      });
    });
    return this.presenter(story);
  }

  async supprimer(utilisateurId: string, storyId: string): Promise<void> {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const story = await this.obtenirStoryVendeur(storyId, boutique.id);
    await this.prisma.story.update({
      where: { id: story.id },
      data: { statut: StatutPublication.SUPPRIMEE },
    });
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

  private async obtenirStoryVendeur(storyId: string, boutiqueId: string) {
    const story = await this.prisma.story.findFirst({
      where: {
        id: storyId,
        boutiqueId,
        statut: { not: StatutPublication.SUPPRIMEE },
      },
      select: { id: true, mediaId: true },
    });
    if (!story) throw new NotFoundException('Story introuvable.');
    return story;
  }

  private presenter(story: StoryAvecRelations) {
    const { media, ...valeurs } = story;
    return {
      ...valeurs,
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
    };
  }
}
