import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import type { StatutSignalement, PrioriteSignalement } from '@dropp/database';

@Injectable()
export class ListerSignalementsService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(params: {
    statut?: StatutSignalement;
    priorite?: PrioriteSignalement;
    page: number;
    limite: number;
  }) {
    const { statut, priorite, page, limite } = params;

    const where = {
      ...(statut && { statut }),
      ...(priorite && { priorite }),
    };

    const [signalements, total] = await this.prisma.$transaction([
      this.prisma.signalement.findMany({
        where,
        select: {
          id: true,
          motif: true,
          description: true,
          statut: true,
          priorite: true,
          dateCreation: true,
          utilisateur: {
            select: { id: true, prenom: true, nom: true },
          },
          publication: { select: { id: true } },
          commentaire: { select: { id: true } },
          produit: { select: { id: true, nom: true } },
          boutique: { select: { id: true, nom: true } },
          messageId: true,
        },
        orderBy: [
          { priorite: 'desc' },
          { dateCreation: 'asc' },
        ],
        skip: (page - 1) * limite,
        take: limite,
      }),
      this.prisma.signalement.count({ where }),
    ]);

    return {
      donnees: signalements,
      pagination: { total, page, limite, pages: Math.ceil(total / limite) },
    };
  }
}