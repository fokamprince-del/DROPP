import { Inject, Injectable, Logger } from '@nestjs/common';
import type { Redis } from 'ioredis';

import { PrismaService } from '../database/prisma.service.js';
import { REDIS_CLIENT } from '../redis/redis.provider.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../stockage/stockage-provider.contract.js';
import { CLE_UPLOADS_EN_ATTENTE } from '../stockage/stockage-suivi.js';

const HEURE = 3_600_000;
const JOUR = 24 * HEURE;

/** Délais avant suppression définitive des fichiers. */
const DELAI_UPLOAD_ABANDONNE = JOUR;
const DELAI_STORY_EXPIREE = 2 * JOUR;
const DELAI_PUBLICATION_SUPPRIMEE = 30 * JOUR; // conservée pour la modération
const DELAI_MEDIA_ORPHELIN = HEURE;
const LOT = 200;

@Injectable()
export class NettoyageService {
  private readonly logger = new Logger(NettoyageService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(STOCKAGE_PROVIDER) private readonly stockage: StockageProvider,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  async executer(): Promise<void> {
    const bilan = {
      uploadsAbandonnes: await this.uploadsAbandonnes(),
      stories: await this.storiesExpirees(),
      publications: await this.publicationsSupprimees(),
      mediasOrphelins: await this.mediasOrphelins(),
      paniersAbandonnes: await this.paniersAbandonnes(),
    };
    this.logger.log(`Nettoyage : ${JSON.stringify(bilan)}`);
  }

  /** Fichiers uploadés via une URL signée mais jamais confirmés. */
  private async uploadsAbandonnes(): Promise<number> {
    const limite = Date.now() - DELAI_UPLOAD_ABANDONNE;
    const cles = await this.redis.zrangebyscore(
      CLE_UPLOADS_EN_ATTENTE,
      0,
      limite,
      'LIMIT',
      0,
      LOT,
    );
    let supprimes = 0;
    for (const cle of cles) {
      // Sécurité : ne jamais effacer un fichier rattaché en base.
      const utilise = await this.prisma.media.count({
        where: { cleStockage: cle, statutTraitement: 'PRET' },
      });
      if (!utilise && (await this.effacerFichier(cle))) supprimes++;
      await this.redis.zrem(CLE_UPLOADS_EN_ATTENTE, cle);
    }
    return supprimes;
  }

  /** Stories expirées ou supprimées : ligne + média + fichier. */
  private async storiesExpirees(): Promise<number> {
    const stories = await this.prisma.story.findMany({
      where: {
        OR: [
          { dateExpiration: { lt: new Date(Date.now() - DELAI_STORY_EXPIREE) } },
          { statut: 'SUPPRIMEE' },
        ],
      },
      select: { id: true, mediaId: true, media: { select: { cleStockage: true } } },
      take: LOT,
    });
    for (const story of stories) {
      await this.prisma.$transaction([
        this.prisma.story.delete({ where: { id: story.id } }),
        this.prisma.media.delete({ where: { id: story.mediaId } }),
      ]);
      await this.effacerFichier(story.media.cleStockage);
    }
    return stories.length;
  }

  /** Médias des publications supprimées depuis plus de 30 jours. */
  private async publicationsSupprimees(): Promise<number> {
    const liens = await this.prisma.mediaPublication.findMany({
      where: {
        publication: {
          statut: 'SUPPRIMEE',
          dateModification: {
            lt: new Date(Date.now() - DELAI_PUBLICATION_SUPPRIMEE),
          },
        },
      },
      select: {
        publicationId: true,
        mediaId: true,
        media: { select: { cleStockage: true } },
      },
      take: LOT,
    });
    for (const lien of liens) {
      await this.prisma.$transaction([
        this.prisma.mediaPublication.delete({
          where: {
            publicationId_mediaId: {
              publicationId: lien.publicationId,
              mediaId: lien.mediaId,
            },
          },
        }),
        this.prisma.media.delete({ where: { id: lien.mediaId } }),
      ]);
      await this.effacerFichier(lien.media.cleStockage);
    }
    return liens.length;
  }

  /** Médias rattachés à rien (ex : produit supprimé). */
  private async mediasOrphelins(): Promise<number> {
    const medias = await this.prisma.media.findMany({
      where: {
        dateCreation: { lt: new Date(Date.now() - DELAI_MEDIA_ORPHELIN) },
        mediaProduits: { none: {} },
        mediaPublications: { none: {} },
        stories: { none: {} },
        piecesJointes: { none: {} },
        preuvesLitige: { none: {} },
      },
      select: { id: true, cleStockage: true },
      take: LOT,
    });
    for (const media of medias) {
      await this.prisma.media.delete({ where: { id: media.id } });
      await this.effacerFichier(media.cleStockage);
    }
    return medias.length;
  }

  /** Paniers inactifs depuis 30 jours : marqués ABANDONNE (données conservées). */
  private async paniersAbandonnes(): Promise<number> {
    const { count } = await this.prisma.panier.updateMany({
      where: {
        statut: 'ACTIF',
        dateModification: { lt: new Date(Date.now() - 30 * JOUR) },
      },
      data: { statut: 'ABANDONNE' },
    });
    return count;
  }

  private async effacerFichier(cle: string): Promise<boolean> {
    try {
      await this.stockage.supprimer(cle);
      return true;
    } catch (erreur) {
      this.logger.warn(`Fichier ${cle} non supprimé : ${String(erreur)}`);
      return false;
    }
  }
}
