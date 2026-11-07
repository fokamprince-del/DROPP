import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { MiseAJourVendeurDto } from './dto/mise-a-jour-vendeur.dto.js';

const vendeurSelection = {
  dateDebut: true,
  statutVendeur: true,
  commissionPersonnalisee: true,
  biographie: true,
  boutique: {
    select: { id: true, nom: true, statut: true },
  },
  // Dernier dossier d'identité : l'app sait où en est la vérification.
  dossiersKyc: {
    orderBy: { dateSoumission: 'desc' as const },
    take: 1,
    select: { id: true, statut: true, motifRejet: true },
  },
} as const;

@Injectable()
export class SellersService {
  constructor(private readonly prisma: PrismaService) {}

  async devenirVendeur(utilisateurId: string) {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: {
        statutCompte: true,
        telephoneVerifieLe: true,
        vendeur: { select: { id: true } },
      },
    });

    if (!utilisateur) throw new ForbiddenException();

    if (utilisateur.telephoneVerifieLe === null) {
      throw new ForbiddenException(
        'Vérifiez votre téléphone avant de devenir vendeur.',
      );
    }

    if (utilisateur.statutCompte !== 'ACTIF') {
      throw new ForbiddenException('Compte indisponible.');
    }

    if (utilisateur.vendeur) {
      throw new ConflictException('Vous avez déjà un profil vendeur.');
    }

    // Profil vendeur + dossier KYC vide : l'app enchaîne sur l'upload des pièces.
    await this.prisma.vendeur.create({
      data: { id: utilisateurId, dossiersKyc: { create: {} } },
    });
  }

  async obtenirProfil(utilisateurId: string) {
    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: utilisateurId },
      select: vendeurSelection,
    });

    if (!vendeur) {
      throw new NotFoundException('Profil vendeur introuvable.');
    }

    return vendeur;
  }

  async mettreAJourProfil(utilisateurId: string, dto: MiseAJourVendeurDto) {
    try {
      return await this.prisma.vendeur.update({
        where: { id: utilisateurId },
        data: dto,
        select: vendeurSelection,
      });
    } catch (error: unknown) {
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        error.code === 'P2025'
      ) {
        throw new NotFoundException('Profil vendeur introuvable.');
      }

      throw error;
    }
  }
}
