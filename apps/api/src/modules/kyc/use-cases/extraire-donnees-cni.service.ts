import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { DossierKycService } from '../services/dossier-kyc.service.js';
import { KycStockageService } from '../services/kyc-stockage.service.js';
import { OcrService } from '../services/ocr.service.js';
import { DroppException } from '../../../infrastructure/http/droppException.js';
import { KYC_ERRORS } from '@dropp/contrats';

@Injectable()
export class ExtraireDonneesCniService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ocr: OcrService,
    private readonly kycStockage: KycStockageService,
    private readonly dossiers: DossierKycService,
  ) {}

  /**
   * Lance l'OCR sur la CNI recto et retourne les données extraites.
   * Le frontend affiche ces données pour validation par l'utilisateur.
   * Rien n'est enregistré en base à cette étape.
   */
  async executer(utilisateurId: string) {
    const dossier = await this.dossiers.modifiable(utilisateurId);

    const recto = await this.prisma.documentKyc.findFirst({
      where: { dossierKycId: dossier.id, typeDocument: 'CNI_RECTO' },
      select: { cleStockage: true },
    });
    if (!recto) {
      throw DroppException.NotFound('CNI recto non uploadée. Uploadez d’abord la CNI recto.', KYC_ERRORS.CNI_RECTO_NOT_UPLOADED);
    }

    const image = await this.kycStockage.getFile(recto.cleStockage);
    if (!image) throw DroppException.NotFound('Image CNI non trouvée.', KYC_ERRORS.CNI_IMAGE_NOT_FOUND);

    const donnees = await this.ocr.extraireDonneesCni(image);
    
    console.debug('Données extraites de la CNI :', donnees);
    return {
      donnees,
      avertissement:
        donnees.confidence < 70
          ? 'La qualité de l’image est faible. Veuillez vérifier soigneusement les informations extraites.'
          : null,
    };
  }
}
