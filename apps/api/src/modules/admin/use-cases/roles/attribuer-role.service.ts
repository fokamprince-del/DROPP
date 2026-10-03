import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';

@Injectable()
export class AttribuerRoleService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(
    utilisateurId: string,
    nomRole: string,
    adminId: string,
  ) {
    const [utilisateur, role] = await Promise.all([
      this.prisma.utilisateur.findUnique({
        where: { id: utilisateurId },
        select: { id: true, statutCompte: true },
      }),
      this.prisma.role.findUnique({
        where: { nom: nomRole },
        select: { id: true, nom: true },
      }),
    ]);

    if (!utilisateur) throw new NotFoundException('Utilisateur introuvable.');
    if (!role) throw new NotFoundException(`Rôle "${nomRole}" introuvable.`);

    if (utilisateur.statutCompte === 'SUPPRIME') {
      throw new BadRequestException('Impossible d\'attribuer un rôle à un compte supprimé.');
    }

    const existant = await this.prisma.utilisateurRole.findUnique({
      where: {
        utilisateurId_roleId: { utilisateurId, roleId: role.id },
      },
    });

    if (existant) {
      throw new BadRequestException('Ce rôle est déjà attribué.');
    }

    await this.prisma.$transaction([
      this.prisma.utilisateurRole.create({
        data: { utilisateurId, roleId: role.id },
      }),
      this.prisma.journalAudit.create({
        data: {
          administrateurId: adminId,
          action: 'ATTRIBUER_ROLE',
          resourceType: 'Utilisateur',
          resourceId: utilisateurId,
          details: { role: nomRole },
        },
      }),
    ]);

    return { utilisateurId, role: nomRole };
  }
}