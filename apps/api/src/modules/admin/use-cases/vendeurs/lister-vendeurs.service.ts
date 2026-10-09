import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import type { StatutKyc, StatutVendeur } from '@dropp/database';

@Injectable()
export class ListerVendeursService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(params: {
    statut?: StatutVendeur;
    statutKyc?: StatutKyc;
    page: number;
    limite: number;
  }) {
    const { statut, statutKyc, page, limite } = params;

    const where = {
      ...(statut && { statutVendeur: statut }),
      ...(statutKyc && {
        dossiersKyc: {
          some: { statut: statutKyc },
        },
      }),
    };

    const [vendeurs, total] = await this.prisma.$transaction([
      this.prisma.vendeur.findMany({
        where,
        select: {
          id: true,
          statutVendeur: true,
          dateDebut: true,
          utilisateur: {
            select: { prenom: true, nom: true, telephone: true, email: true },
          },
          boutique: { select: { nom: true, statut: true } },
          dossiersKyc: {
            orderBy: { dateSoumission: 'desc' },
            take: 1,
            select: { id: true, statut: true, scoreFaceMatch: true },
          },
        },
        orderBy: { dateDebut: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
      }),
      this.prisma.vendeur.count({ where }),
    ]);

    return {
      donnees: vendeurs,
      pagination: { total, page, limite, pages: Math.ceil(total / limite) },
    };
  }
}