import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { StatutCategorie } from '@dropp/database';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { CreerCategorieDto } from './dto/creer-categorie.dto.js';
import { MiseAJourCategorieDto } from './dto/mise-a-jour-categorie.dto.js';

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Arbre des catégories pour les filtres de l'onglet Marché, avec le nombre
   * de produits publiés. Le total d'une catégorie parente inclut ses sous-catégories.
   */
  async listerPubliques() {
    const compte = {
      _count: {
        select: {
          produits: {
            where: { statut: 'PUBLIE' as const, boutique: { statut: 'ACTIVE' as const } },
          },
        },
      },
    };
    const parents = await this.prisma.categorie.findMany({
      where: { statut: StatutCategorie.ACTIVE, parentId: null },
      include: {
        ...compte,
        enfants: {
          where: { statut: StatutCategorie.ACTIVE },
          orderBy: { nom: 'asc' },
          include: compte,
        },
      },
      orderBy: { nom: 'asc' },
    });

    return parents.map(({ _count, enfants, ...parent }) => {
      const sous = enfants.map(({ _count: c, ...e }) => ({
        ...e,
        nombreProduits: c.produits,
      }));
      return {
        ...parent,
        nombreProduits: _count.produits + sous.reduce((s, e) => s + e.nombreProduits, 0),
        enfants: sous,
      };
    });
  }

  listerAdministration() {
    return this.prisma.categorie.findMany({
      include: { _count: { select: { produits: true, enfants: true } } },
      orderBy: { nom: 'asc' },
    });
  }

  async creer(dto: CreerCategorieDto) {
    if (dto.parentId) {
      await this.obtenir(dto.parentId);
    }

    return this.prisma.categorie.create({ data: dto });
  }

  async mettreAJour(id: string, dto: MiseAJourCategorieDto) {
    if (dto.parentId) {
      await this.verifierParentValide(id, dto.parentId);
    }

    try {
      return await this.prisma.categorie.update({ where: { id }, data: dto });
    } catch (error: unknown) {
      if (this.estIntrouvable(error)) {
        throw new NotFoundException('Catégorie introuvable.');
      }
      throw error;
    }
  }

  async changerStatut(id: string, statut: StatutCategorie) {
    try {
      return await this.prisma.categorie.update({
        where: { id },
        data: { statut },
      });
    } catch (error: unknown) {
      if (this.estIntrouvable(error)) {
        throw new NotFoundException('Catégorie introuvable.');
      }
      throw error;
    }
  }

  private async obtenir(id: string) {
    const categorie = await this.prisma.categorie.findUnique({ where: { id } });
    if (!categorie) {
      throw new NotFoundException('Catégorie parente introuvable.');
    }
    return categorie;
  }

  private async verifierParentValide(
    categorieId: string,
    parentId: string,
  ): Promise<void> {
    let parent = await this.obtenir(parentId);

    while (true) {
      if (parent.id === categorieId) {
        throw new ConflictException(
          'Une catégorie ne peut pas être son propre ancêtre.',
        );
      }

      if (!parent.parentId) {
        return;
      }

      parent = await this.obtenir(parent.parentId);
    }
  }

  private estIntrouvable(error: unknown): boolean {
    return (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      error.code === 'P2025'
    );
  }
}
