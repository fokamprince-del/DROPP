import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { MiseAJourProfilDto } from './dto/mise-a-jour-profil.dto.js';

const profilSelection = {
  id: true,
  nom: true,
  prenom: true,
  email: true,
  telephone: true,
  photoProfilUrl: true,
  dateInscription: true,
  statutCompte: true,
  derniereConnexion: true,
  client: {
    select: {
      statutClient: true,
    },
  },
  vendeur: {
    select: {
      statutVendeur: true,
      biographie: true,
      boutique: {
        select: {
          id: true,
          nom: true,
          statut: true,
        },
      },
    },
  },
  roles: {
    select: {
      role: {
        select: {
          nom: true,
        },
      },
    },
  },
} as const;

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async obtenirProfil(utilisateurId: string) {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: profilSelection,
    });

    if (!utilisateur) {
      throw new NotFoundException('Utilisateur introuvable.');
    }

    return utilisateur;
  }

  async mettreAJourProfil(
    utilisateurId: string,
    dto: MiseAJourProfilDto,
  ) {
    try {
      const utilisateur = await this.prisma.utilisateur.update({
        where: { id: utilisateurId },
        data: dto,
        select: profilSelection,
      });

      return utilisateur;
    } catch (error: unknown) {
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        error.code === 'P2002'
      ) {
        throw new ConflictException(
          'Ce numéro de téléphone est déjà utilisé.',
        );
      }

      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        error.code === 'P2025'
      ) {
        throw new NotFoundException('Utilisateur introuvable.');
      }

      throw error;
    }
  }
}
