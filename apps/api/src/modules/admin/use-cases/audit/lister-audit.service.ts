import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';

@Injectable()
export class ListerAuditService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(params: {
    adminId?: string;
    action?: string;
    resourceType?: string;
    page: number;
    limite: number;
  }) {
    const { adminId, action, resourceType, page, limite } = params;

    const where = {
      ...(adminId && { administrateurId: adminId }),
      ...(action && { action: { contains: action } }),
      ...(resourceType && { resourceType }),
    };

    const [logs, total] = await this.prisma.$transaction([
      this.prisma.journalAudit.findMany({
        where,
        select: {
          id: true,
          action: true,
          resourceType: true,
          resourceId: true,
          adresseIp: true,
          details: true,
          dateCreation: true,
          administrateur: {
            select: { id: true, prenom: true, nom: true },
          },
        },
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limite,
        take: limite,
      }),
      this.prisma.journalAudit.count({ where }),
    ]);

    return {
      donnees: logs,
      pagination: { total, page, limite, pages: Math.ceil(total / limite) },
    };
  }
}