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
} from '@dropp/database';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../infrastructure/stockage/stockage-provider.contract.js';
import { verifierUpload } from '../../infrastructure/stockage/verifier-upload.js';
import { racineContenu, urlLecture } from '../../infrastructure/stockage/lecture.js';
import type { ConfirmerStoryDto } from './dto/confirmer-story.dto.js';
import type { CreerStoryDto } from './dto/creer-story.dto.js';

const TAILLE_MAX_PAR_TYPE: Record<string, number> = {
  'image/jpeg': 10,
  'image/png': 10,
  'image/webp': 10,
  'video/mp4': 500,
  'video/quicktime': 500,
};

const DUREE_MAX_STORY_MS = 24 * 3_600_000;

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
    return Promise.all(stories.map((story) => this.presenter(story)));
  }

  /**
   * Stories actives des boutiques suivies (y compris visibilité ABONNES),
   * regroupées par boutique, avec l'état « déjà vue » pour chaque story.
   * Les boutiques avec des stories non vues passent en premier.
   */
  async listerAbonnements(utilisateurId: string) {
    const stories = await this.prisma.story.findMany({
      where: {
        statut: StatutPublication.PUBLIEE,
        dateExpiration: { gt: new Date() },
        boutique: {
          statut: 'ACTIVE',
          vendeur: {
            abonnements: { some: { utilisateurId, statut: 'ACTIF' } },
          },
        },
      },
      select: {
        ...storySelection,
        vues: { where: { utilisateurId }, select: { dateVue: true } },
      },
      orderBy: { dateCreation: 'asc' },
    });

    const parBoutique = new Map<
      string,
      {
        boutique: { id: string; nom: string };
        toutesVues: boolean;
        stories: (Awaited<ReturnType<StoriesService['presenter']>> & { vue: boolean })[];
      }
    >();
    for (const { vues, ...story } of stories) {
      const groupe = parBoutique.get(story.boutique.id) ?? {
        boutique: story.boutique,
        toutesVues: true,
        stories: [],
      };
      const vue = vues.length > 0;
      groupe.toutesVues &&= vue;
      groupe.stories.push({ ...(await this.presenter(story)), vue });
      parBoutique.set(story.boutique.id, groupe);
    }
    return [...parBoutique.values()].sort(
      (a, b) => Number(a.toutesVues) - Number(b.toutesVues),
    );
  }

  /** Enregistre une vue (idempotent). Le propriétaire ne compte pas. */
  async marquerVue(utilisateurId: string, storyId: string) {
    const story = await this.prisma.story.findFirst({
      where: {
        id: storyId,
        statut: StatutPublication.PUBLIEE,
        dateExpiration: { gt: new Date() },
        // Story réservée aux abonnés : seuls eux (et la boutique) peuvent la voir.
        OR: [
          { visibilite: 'PUBLIC' },
          { boutiqueId: utilisateurId },
          {
            boutique: {
              vendeur: {
                abonnements: { some: { utilisateurId, statut: 'ACTIF' } },
              },
            },
          },
        ],
      },
      select: { boutiqueId: true },
    });
    if (!story) throw new NotFoundException('Story introuvable.');
    if (story.boutiqueId !== utilisateurId) {
      await this.prisma.vueStory.upsert({
        where: { storyId_utilisateurId: { storyId, utilisateurId } },
        create: { storyId, utilisateurId },
        update: {},
      });
    }
    return { storyId, vue: true };
  }

  /** « Qui a vu ma story » — réservé à la boutique propriétaire. */
  async listerVues(utilisateurId: string, storyId: string) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    await this.obtenirStoryVendeur(storyId, boutique.id);
    const vues = await this.prisma.vueStory.findMany({
      where: { storyId },
      orderBy: { dateVue: 'desc' },
      select: {
        dateVue: true,
        utilisateur: {
          select: { id: true, prenom: true, nom: true, pseudo: true, photoProfilCle: true },
        },
      },
    });
    return {
      total: vues.length,
      spectateurs: vues.map(({ dateVue, utilisateur: { photoProfilCle, ...u } }) => ({
        ...u,
        photoProfilUrl: photoProfilCle
          ? this.stockage.urlPublique(photoProfilCle, { largeur: 100, hauteur: 100 })
          : null,
        dateVue,
      })),
    };
  }

  async listerMesStories(utilisateurId: string) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const stories = await this.prisma.story.findMany({
      where: { boutiqueId: boutique.id },
      select: storySelection,
      orderBy: { dateCreation: 'desc' },
    });
    return Promise.all(stories.map((story) => this.presenter(story)));
  }

  async creer(utilisateurId: string, dto: CreerStoryDto) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const maintenant = Date.now();
    const dateExpiration =
      dto.dateExpiration ?? new Date(maintenant + DUREE_MAX_STORY_MS);
    if (dateExpiration.getTime() <= maintenant) {
      throw new BadRequestException('La date d’expiration doit être future.');
    }
    if (dateExpiration.getTime() > maintenant + DUREE_MAX_STORY_MS) {
      throw new BadRequestException('Une story dure au maximum 24 heures.');
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
      `${this.dossierStory(boutique.id, storyId, dto.visibilite)}/${typeMedia.toLowerCase()}s`,
      dto.typeMime,
      tailleMax,
    );

    const story = await this.prisma.story.create({
      data: {
        id: storyId,
        boutique: { connect: { id: boutique.id } },
        visibilite: dto.visibilite,
        statut: StatutPublication.PROCESSING,
        dateExpiration,
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

    return { story: await this.presenter(story), signature, typeMedia };
  }

  async confirmer(
    utilisateurId: string,
    storyId: string,
    dto: ConfirmerStoryDto,
  ) {
    const boutique = await this.obtenirBoutiqueActive(utilisateurId);
    const storyExistante = await this.obtenirStoryVendeur(storyId, boutique.id);
    const tailleMax = TAILLE_MAX_PAR_TYPE[dto.typeMime];
    if (!tailleMax) {
      throw new BadRequestException('Type de fichier non pris en charge.');
    }
    const reel = await verifierUpload(this.stockage, {
      cleStockage: dto.cleStockage,
      prefixe: this.dossierStory(boutique.id, storyId, storyExistante.visibilite),
      tailleMaxMo: tailleMax,
      typesMime: [dto.typeMime],
    });

    const typeMedia = dto.typeMime.startsWith('video/')
      ? TypeMedia.VIDEO
      : TypeMedia.IMAGE;
    // Pas de transcodage : la story est publiée dès que le fichier est là.
    const statutTraitement = StatutTraitementMedia.PRET;

    const story = await this.prisma.$transaction(async (tx) => {
      await tx.media.update({
        where: { id: storyExistante.mediaId },
        data: {
          typeMedia,
          cleStockage: dto.cleStockage,
          typeMime: dto.typeMime,
          taille: reel.taille,
          largeur: dto.largeur,
          hauteur: dto.hauteur,
          duree: dto.duree,
          statutTraitement,
        },
      });
      return tx.story.update({
        where: { id: storyId },
        data: { statut: StatutPublication.PUBLIEE },
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
      select: { id: true, mediaId: true, visibilite: true },
    });
    if (!story) throw new NotFoundException('Story introuvable.');
    return story;
  }

  /** Dossier des médias : sous abonnes/ (bucket privé) si réservée aux abonnés. */
  private dossierStory(
    boutiqueId: string,
    storyId: string,
    visibilite: 'PUBLIC' | 'ABONNES',
  ) {
    return racineContenu(visibilite, `boutiques/${boutiqueId}/stories/${storyId}`);
  }

  private async presenter(story: StoryAvecRelations) {
    const { media, ...valeurs } = story;
    const url = await urlLecture(this.stockage, media.cleStockage);
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
        url,
      },
    };
  }
}
