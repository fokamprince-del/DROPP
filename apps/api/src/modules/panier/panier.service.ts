import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import type { AjouterArticlePanierDto } from './dto/ajouter-article-panier.dto.js';

const panierSelect = {
  id: true,
  statut: true,
  dateModification: true,
  articles: {
    orderBy: { dateAjout: 'asc' as const },
    select: {
      id: true,
      varianteProduitId: true,
      quantite: true,
      prixUnitaire: true,
      varianteProduit: {
        select: {
          id: true,
          sku: true,
          nom: true,
          attributs: true,
          stockDisponible: true,
          prix: true,
          produit: {
            select: { id: true, nom: true, prixBase: true, boutiqueId: true },
          },
        },
      },
    },
  },
} as const;

@Injectable()
export class PanierService {
  constructor(private readonly prisma: PrismaService) {}

  async obtenir(utilisateurId: string) {
    const panier = await this.prisma.panier.findFirst({
      where: { utilisateurId, statut: 'ACTIF' },
      select: panierSelect,
    });
    return this.formater(panier);
  }

  async ajouter(utilisateurId: string, dto: AjouterArticlePanierDto) {
    const variante = await this.prisma.varianteProduit.findUnique({
      where: { id: dto.varianteProduitId },
      select: {
        id: true,
        prix: true,
        produit: {
          select: { id: true, nom: true, prixBase: true, statut: true },
        },
      },
    });
    if (!variante || variante.produit.statut !== 'PUBLIE')
      throw new NotFoundException('Variante introuvable.');
    const prixUnitaire = variante.prix ?? variante.produit.prixBase;
    const panier = await this.panierActif(utilisateurId);
    const articleExistant = await this.prisma.articlePanier.findUnique({
      where: {
        panierId_varianteProduitId: {
          panierId: panier.id,
          varianteProduitId: dto.varianteProduitId,
        },
      },
      select: { quantite: true },
    });
    if ((articleExistant?.quantite ?? 0) + dto.quantite > 1_000)
      throw new BadRequestException('Quantité maximale dépassée.');
    const article = await this.prisma.articlePanier.upsert({
      where: {
        panierId_varianteProduitId: {
          panierId: panier.id,
          varianteProduitId: dto.varianteProduitId,
        },
      },
      create: {
        panierId: panier.id,
        varianteProduitId: dto.varianteProduitId,
        quantite: dto.quantite,
        prixUnitaire,
      },
      update: { quantite: { increment: dto.quantite }, prixUnitaire },
    });
    return this.obtenir(utilisateurId);
  }

  async modifier(utilisateurId: string, articleId: string, quantite: number) {
    const panier = await this.panierActif(utilisateurId);
    const article = await this.prisma.articlePanier.findFirst({
      where: { id: articleId, panierId: panier.id },
    });
    if (!article) throw new NotFoundException('Article de panier introuvable.');
    await this.prisma.articlePanier.update({
      where: { id: articleId },
      data: { quantite },
    });
    return this.obtenir(utilisateurId);
  }

  async supprimer(utilisateurId: string, articleId: string) {
    const panier = await this.panierActif(utilisateurId);
    const resultat = await this.prisma.articlePanier.deleteMany({
      where: { id: articleId, panierId: panier.id },
    });
    if (!resultat.count)
      throw new NotFoundException('Article de panier introuvable.');
    return this.obtenir(utilisateurId);
  }

  async panierActif(utilisateurId: string) {
    const existant = await this.prisma.panier.findFirst({
      where: { utilisateurId, statut: 'ACTIF' },
      select: { id: true },
    });
    if (existant) return existant;
    return this.prisma.panier.create({
      data: { utilisateurId, statut: 'ACTIF' },
      select: { id: true },
    });
  }

  private formater(panier: any) {
    if (!panier) return { id: null, articles: [], sousTotal: 0, devise: 'XAF' };
    const articles = panier.articles.map((article: any) => ({
      ...article,
      prixUnitaire: Number(article.prixUnitaire),
      total: Number(article.prixUnitaire) * article.quantite,
    }));
    return {
      ...panier,
      articles,
      sousTotal: articles.reduce(
        (total: number, article: any) => total + article.total,
        0,
      ),
      devise: 'XAF',
    };
  }
}
