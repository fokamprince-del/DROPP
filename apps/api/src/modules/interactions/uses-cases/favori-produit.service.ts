import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

@Injectable()
export class FavoriProduitService {
  constructor(private readonly prisma: PrismaService) {}

  async ajouter(utilisateurId: string, produitId: string) {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: { id: true, statut: true },
    });

    if (!produit || produit.statut !== 'PUBLIE') {
      throw new NotFoundException('Produit introuvable.');
    }

    try {
      await this.prisma.favoriProduit.create({
        data: { utilisateurId, produitId },
      });
    } catch (e: unknown) {
      if (this.estViolationUnicite(e)) {
        throw new ConflictException('Déjà dans vos favoris.');
      }
      throw e;
    }

    return { produitId, enFavori: true };
  }

  async retirer(utilisateurId: string, produitId: string) {
    const favori = await this.prisma.favoriProduit.findUnique({
      where: {
        utilisateurId_produitId: { utilisateurId, produitId },
      },
      select: { id: true },
    });

    if (!favori) throw new NotFoundException('Favori introuvable.');

    await this.prisma.favoriProduit.delete({
      where: {
        utilisateurId_produitId: { utilisateurId, produitId },
      },
    });

    return { produitId, enFavori: false };
  }

  async lister(utilisateurId: string, page: number) {
    const limite = 20;
    const [favoris, total] = await this.prisma.$transaction([
      this.prisma.favoriProduit.findMany({
        where: { utilisateurId },
        select: {
          dateCreation: true,
          produit: {
            select: {
              id: true,
              nom: true,
              prixBase: true,
              statut: true,
              boutique: { select: { id: true, nom: true } },
              medias: {
                where: { ordre: 0 },
                select: {
                  media: { select: { cleStockage: true } },
                },
                take: 1,
              },
            },
          },
        },
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
      }),
      this.prisma.favoriProduit.count({ where: { utilisateurId } }),
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
