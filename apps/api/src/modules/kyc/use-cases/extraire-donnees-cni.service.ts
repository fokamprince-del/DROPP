import { Injectable, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { DossierKycService } from '../services/dossier-kyc.service.js';
import { KycStockageService } from '../services/kyc-stockage.service.js';
import { OcrService } from '../services/ocr.service.js';

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
      throw new NotFoundException(
        'CNI recto non uploadée. Uploadez d’abord la CNI recto.',
      );
    }

    const image = await this.kycStockage.getFile(recto.cleStockage);
    if (!image) throw new NotFoundException('Image CNI non trouvée.');

    const donnees = await this.ocr.extraireDonneesCni(image);
    return {
      donnees,
      avertissement:
        donnees.confidence < 70
          ? 'La qualité de l’image est faible. Veuillez vérifier soigneusement les informations extraites.'
          : null,
    };
  }
}
