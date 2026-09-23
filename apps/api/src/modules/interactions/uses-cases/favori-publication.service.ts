import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { verifierPublicationVisible } from '../utils/publications.js';

@Injectable()
export class FavoriPublicationService {
  constructor(private readonly prisma: PrismaService) {}

  async ajouter(utilisateurId: string, publicationId: string) {
    await verifierPublicationVisible(this.prisma, publicationId);
    try {
      await this.prisma.favoriPublication.create({
        data: { utilisateurId, publicationId },
      });
    } catch (e: unknown) {
      if (this.estViolationUnicite(e)) {
        throw new ConflictException('Déjà dans vos favoris.');
      }
      throw e;
    }

    return { publicationId, enFavori: true };
  }

  async retirer(utilisateurId: string, publicationId: string) {
    const favori = await this.prisma.favoriPublication.findUnique({
      where: {
        utilisateurId_publicationId: { utilisateurId, publicationId },
      },
      select: { id: true },
    });

    if (!favori) throw new NotFoundException('Favori introuvable.');

    await this.prisma.favoriPublication.delete({
      where: {
        utilisateurId_publicationId: { utilisateurId, publicationId },
      },
    });

    return { publicationId, enFavori: false };
  }

  async lister(utilisateurId: string, page: number) {
    const limite = 20;
    const [favoris, total] = await this.prisma.$transaction([
      this.prisma.favoriPublication.findMany({
        where: { utilisateurId },
        select: {
          dateCreation: true,
          publication: {
            select: {
              id: true,
              contenu: true,
              type: true,
              dateCreation: true,
              boutique: { select: { id: true, nom: true } },
            },
          },
        },
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
      }),
      this.prisma.favoriPublication.count({ where: { utilisateurId } }),
    ]);

    return {
      donnees: favoris,
      pagination: { total, page, pages: Math.ceil(total / limite) },
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
}
