import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { EnregistrerBoutiqueDto } from './dto/enregistrer-boutique.dto.js';
import { MiseAJourBoutiqueDto } from './dto/mise-a-jour-boutique.dto.js';

const boutiqueSelection = {
  id: true,
  nom: true,
  description: true,
  biographie: true,
  statut: true,
  dateCreation: true,
  dateModification: true,
} as const;

@Injectable()
export class ShopsService {
  constructor(private readonly prisma: PrismaService) {}

  async obtenirMaBoutique(vendeurId: string) {
    const boutique = await this.prisma.boutique.findUnique({
      where: { id: vendeurId },
      select: boutiqueSelection,
    });

    if (!boutique) {
      throw new NotFoundException('Boutique introuvable.');
    }

    return boutique;
  }

  async creerBoutique(vendeurId: string, dto: EnregistrerBoutiqueDto) {
    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: vendeurId },
      select: {
        id: true,
        statutVendeur: true,
        boutique: { select: { id: true } },
      },
    });

    if (!vendeur) {
      throw new NotFoundException('Profil vendeur introuvable.');
    }

    if (vendeur.statutVendeur !== 'ACTIF') {
      throw new ForbiddenException(
        'La validation KYC est requise avant de créer une boutique.',
      );
    }

    if (vendeur.boutique) {
      throw new ConflictException('Ce vendeur possède déjà une boutique.');
    }

    return this.prisma.boutique.create({
      data: { id: vendeurId, ...dto },
      select: boutiqueSelection,
    });
  }

  async mettreAJourMaBoutique(
    vendeurId: string,
    dto: MiseAJourBoutiqueDto,
  ) {
    try {
      return await this.prisma.boutique.update({
        where: { id: vendeurId },
        data: dto,
        select: boutiqueSelection,
      });
    } catch (error: unknown) {
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        error.code === 'P2025'
      ) {
        throw new NotFoundException('Boutique introuvable.');
      }

      throw error;
    }
  }
}
