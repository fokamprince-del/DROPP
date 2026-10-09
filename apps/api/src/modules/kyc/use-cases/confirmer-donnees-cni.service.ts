import { BadRequestException, Injectable } from '@nestjs/common';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { DonneesCniDto } from '../dto/donnees-cni.dto.js';
import { DossierKycService } from '../services/dossier-kyc.service.js';

/** Âge minimum pour vendre sur la plateforme. */
const AGE_MINIMUM = 18;

@Injectable()
export class ConfirmerDonneesCniService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly dossiers: DossierKycService,
  ) {}

  /** Enregistre les données CNI validées par l'utilisateur. */
  async executer(utilisateurId: string, dto: DonneesCniDto) {
    const dossier = await this.dossiers.modifiable(utilisateurId);

    const maintenant = new Date();
    if (dto.dateExpiration < maintenant) {
      throw new BadRequestException('Votre carte d’identité est expirée.');
    }
    if (dto.dateEtablissement >= dto.dateExpiration) {
      throw new BadRequestException('Dates de la carte d’identité incohérentes.');
    }
    if (dto.dateNaissance >= dto.dateEtablissement) {
      throw new BadRequestException('Date de naissance incohérente.');
    }
    const majorite = new Date(dto.dateNaissance);
    majorite.setFullYear(majorite.getFullYear() + AGE_MINIMUM);
    if (majorite > maintenant) {
      throw new BadRequestException(
        `Vous devez avoir au moins ${AGE_MINIMUM} ans pour vendre sur DROPP.`,
      );
    }

    return this.prisma.dossierKyc.update({
      where: { id: dossier.id },
      data: {
        nomLegal: dto.nomLegal,
        prenomLegal: dto.prenomLegal,
        numeroCni: dto.numeroCni,
        dateNaissance: dto.dateNaissance,
        lieuNaissance: dto.lieuNaissance,
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
}
