import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { DonneesCniDto } from '../dto/donnees-cni.dto.js';
import { DossierKycService } from '../services/dossier-kyc.service.js';
import { DroppException } from '../../../infrastructure/http/droppException.js';
import { KYC_ERRORS } from '@dropp/contrats';

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
      throw DroppException.UnprocessableEntity('Votre carte d’identité est expirée.', KYC_ERRORS.INVALID_EXPIRATION_DATE);
    }
    if (dto.dateEtablissement >= dto.dateExpiration) {
      throw DroppException.UnprocessableEntity('Dates de la carte d’identité incohérentes.', KYC_ERRORS.INVALID_ISSUE_DATE);
    }
    if (dto.dateNaissance >= dto.dateEtablissement) {
      throw DroppException.UnprocessableEntity('Date de naissance incohérente.', KYC_ERRORS.INVALID_BIRTH_DATE);
    }
    const majorite = new Date(dto.dateNaissance);
    majorite.setFullYear(majorite.getFullYear() + AGE_MINIMUM);
    if (majorite > maintenant) {
      throw DroppException.UnprocessableEntity(
        `Vous devez avoir au moins ${AGE_MINIMUM} ans pour vendre sur DROPP.`,
        KYC_ERRORS.MINIMUM_AGE_NOT_MET,
        {
          ageMinimum: AGE_MINIMUM,
          dateNaissance: dto.dateNaissance.toISOString(),
          dateLimite: majorite.toISOString(),
        }
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
