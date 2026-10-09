import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import type { StatutCompte } from '@dropp/database';

@Injectable()
export class ListerUtilisateursService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(params: {
    statut?: StatutCompte;
    recherche?: string;
    page: number;
    limite: number;
  }) {
    const { statut, recherche, page, limite } = params;

    const where = {
      ...(statut && { statutCompte: statut }),
      ...(recherche && {
        OR: [
          { prenom: { contains: recherche, mode: 'insensitive' as const } },
          { nom: { contains: recherche, mode: 'insensitive' as const } },
          { telephone: { contains: recherche } },
          { email: { contains: recherche, mode: 'insensitive' as const } },
        ],
      }),
    };

    const [utilisateurs, total] = await this.prisma.$transaction([
      this.prisma.utilisateur.findMany({
        where,
        select: {
          id: true,
          prenom: true,
          nom: true,
          telephone: true,
          email: true,
          statutCompte: true,
          dateInscription: true,
          telephoneVerifieLe: true,
          client: { select: { statutClient: true } },
          vendeur: { select: { statutVendeur: true } },
          roles: { select: { role: { select: { nom: true } } } },
        },
        orderBy: { dateInscription: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
      }),
      this.prisma.utilisateur.count({ where }),
    ]);

    return {
      donnees: utilisateurs.map((u) => ({
        ...u,
        roles: u.roles.map((r) => r.role.nom),
      })),
      pagination: { total, page, limite, pages: Math.ceil(total / limite) },
    };
  }
}