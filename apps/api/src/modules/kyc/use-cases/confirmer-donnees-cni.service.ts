import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { DonneesCniDto } from '../dto/donnees-cni.dto.js';

@Injectable()
export class ConfirmerDonneesCniService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Enregistre les données CNI validées par l'utilisateur.
   */
  async executer(utilisateurId: string, dto: DonneesCniDto) {
    const dossier = await this.getDossierModifiable(utilisateurId);

    // Vérifier que la CNI n'est pas expirée
    if (dto.dateExpiration < new Date()) {
      throw new BadRequestException('Votre carte d\'identité est expirée.');
    }

    return this.prisma.dossierKyc.update({
      where: { id: dossier.id },
      data: {
        nomLegal: dto.nomLegal.trim(),
        prenomLegal: dto.prenomLegal.trim(),
        numeroCni: dto.numeroCni.trim(),
        dateNaissance: dto.dateNaissance,
        lieuNaissance: dto.lieuNaissance.trim(),
        dateEtablissement: dto.dateEtablissement,
        dateExpiration: dto.dateExpiration,
      },
      select: {
        id: true,
        nomLegal: true,
        prenomLegal: true,
        numeroCni: true,
        dateNaissance: true,
        lieuNaissance: true,
        dateEtablissement: true,
        dateExpiration: true,
      },
    });
  }

  private async getDossierModifiable(utilisateurId: string) {
    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: utilisateurId },
      select: {
        dossiersKyc: {
          orderBy: { dateSoumission: 'desc' },
          take: 1,
          select: { id: true, statut: true },
        },
      },
    });

    if (!vendeur) throw new ForbiddenException('Profil vendeur introuvable.');

    const dossier = vendeur.dossiersKyc[0];
    if (!dossier) throw new NotFoundException('Dossier KYC introuvable.');

    if (!['EN_ATTENTE', 'REJETE'].includes(dossier.statut)) {
      throw new BadRequestException('Le dossier ne peut plus être modifié.');
    }

    return dossier;
  }
}