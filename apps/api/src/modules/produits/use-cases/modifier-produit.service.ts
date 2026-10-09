import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { ModifierProduitDto } from '../dto/modifier-produit.dto.js';
import { PublicationAutoService } from '../services/publication-auto.service.js';

const produitSelection = {
  id: true,
  nom: true,
  statut: true,
  prixBase: true,
  boutiqueId: true,
  categorieId: true,
  dateCreation: true,
  dateModification: true,
} as const;

@Injectable()
export class ModifierProduitService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly publicationAuto: PublicationAutoService,
  ) {}

  /** Le produit reste en ligne si, après modification, il est toujours complet. */
  async executer(
    produitId: string,
    boutiqueId: string,
    dto: ModifierProduitDto,
  ) {
    await this.verifierAppartenance(produitId, boutiqueId);

    if (dto.categorieId) {
      const cat = await this.prisma.categorie.findUnique({
        where: { id: dto.categorieId },
        select: { statut: true },
      });
      if (!cat || cat.statut !== 'ACTIVE') {
        throw new BadRequestException('Catégorie invalide ou inactive.');
      }
    }

    await this.prisma.produit.update({
      where: { id: produitId },
      data: {
        ...(dto.nom && { nom: dto.nom }),
        ...(dto.description && { description: dto.description }),
        ...(dto.categorieId && { categorieId: dto.categorieId }),
        ...(dto.prixBase !== undefined && { prixBase: dto.prixBase }),
      },
    });
    await this.publicationAuto.tenter(produitId);

    return this.prisma.produit.findUniqueOrThrow({
      where: { id: produitId },
      select: produitSelection,
    });
  }

  /** Retire le produit de la vente sans le supprimer (historique de commandes conservé). */
  async archiver(produitId: string, boutiqueId: string) {
    await this.verifierAppartenance(produitId, boutiqueId);
    const { count } = await this.prisma.produit.updateMany({
      where: { id: produitId, statut: { notIn: ['ARCHIVE', 'REJETE'] } },
      data: { statut: 'ARCHIVE' },
    });
    if (count === 0) {
      throw new BadRequestException('Ce produit ne peut pas être archivé.');
    }
    return this.prisma.produit.findUniqueOrThrow({
      where: { id: produitId },
      select: produitSelection,
    });
  }

  /** Remet un produit archivé en brouillon, puis le republie s'il est complet. */
  async restaurer(produitId: string, boutiqueId: string) {
    await this.verifierAppartenance(produitId, boutiqueId);
    const { count } = await this.prisma.produit.updateMany({
      where: { id: produitId, statut: 'ARCHIVE' },
      data: { statut: 'BROUILLON' },
    });
    if (count === 0) {
      throw new BadRequestException('Seul un produit archivé peut être restauré.');
    }
    await this.publicationAuto.tenter(produitId);
    return this.prisma.produit.findUniqueOrThrow({
      where: { id: produitId },
      select: produitSelection,
    });
  }

  private async verifierAppartenance(produitId: string, boutiqueId: string) {
    const produit = await this.prisma.produit.findUnique({
      where: { id: produitId },
      select: { boutiqueId: true },
    });
    if (!produit) throw new NotFoundException('Produit introuvable.');
    if (produit.boutiqueId !== boutiqueId)
      throw new ForbiddenException('Accès refusé.');
  }
}
