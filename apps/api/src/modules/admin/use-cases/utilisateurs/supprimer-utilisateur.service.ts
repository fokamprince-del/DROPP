import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';

@Injectable()
export class SupprimerUtilisateurService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(utilisateurId: string, adminId: string, raison: string) {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: { id: true, statutCompte: true },
    });

    if (!utilisateur) throw new NotFoundException('Utilisateur introuvable.');

    if (utilisateur.statutCompte === 'SUPPRIME') {
      throw new BadRequestException('Compte déjà supprimé.');
    }

    // On ne peut pas supprimer un super admin
    const estSuperAdmin = await this.prisma.utilisateurRole.findFirst({
      where: {
        utilisateurId,
        role: { nom: 'SUPER_ADMIN' },
      },
    });

    if (estSuperAdmin) {
      throw new BadRequestException(
        'Impossible de supprimer un super administrateur.',
      );
    }

    await this.prisma.$transaction([
      // Soft delete : on passe en SUPPRIME et on anonymise
      this.prisma.utilisateur.update({
        where: { id: utilisateurId },
        data: {
          statutCompte: 'SUPPRIME',
          telephone: null,
          email: null,
          motDePasseHash: null,
        },
      }),
      // Révoquer toutes les sessions
      this.prisma.session.updateMany({
        where: { utilisateurId, dateRevocation: null },
        data: { dateRevocation: new Date() },
      }),
      this.prisma.journalAudit.create({
        data: {
          administrateurId: adminId,
          action: 'SUPPRIMER_UTILISATEUR',
          resourceType: 'Utilisateur',
          resourceId: utilisateurId,
          details: { raison },
        },
      }),
    ]);

    return { message: 'Compte supprimé et anonymisé.' };
  }
}