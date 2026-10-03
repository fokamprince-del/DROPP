import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';

@Injectable()
export class RetirerRoleService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(
    utilisateurId: string,
    nomRole: string,
    adminId: string,
  ) {
    // On ne peut pas retirer le SUPER_ADMIN du dernier super admin
    if (nomRole === 'SUPER_ADMIN') {
      const totalSuperAdmins = await this.prisma.utilisateurRole.count({
        where: { role: { nom: 'SUPER_ADMIN' } },
      });

      if (totalSuperAdmins <= 1) {
        throw new BadRequestException(
          'Impossible de retirer le dernier SUPER_ADMIN.',
        );
      }
    }

    const role = await this.prisma.role.findUnique({
      where: { nom: nomRole },
      select: { id: true },
    });

    if (!role) throw new NotFoundException(`Rôle "${nomRole}" introuvable.`);

    const attribution = await this.prisma.utilisateurRole.findUnique({
      where: {
        utilisateurId_roleId: { utilisateurId, roleId: role.id },
      },
    });

    if (!attribution) {
      throw new NotFoundException('Ce rôle n\'est pas attribué à cet utilisateur.');
    }

    await this.prisma.$transaction([
      this.prisma.utilisateurRole.delete({
        where: {
          utilisateurId_roleId: { utilisateurId, roleId: role.id },
        },
      }),
      this.prisma.journalAudit.create({
        data: {
          administrateurId: adminId,
          action: 'RETIRER_ROLE',
          resourceType: 'Utilisateur',
          resourceId: utilisateurId,
          details: { role: nomRole },
        },
      }),
    ]);

    return { utilisateurId, roleRetiré: nomRole };
  }
}