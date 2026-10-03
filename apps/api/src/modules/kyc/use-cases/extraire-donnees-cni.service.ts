import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { OcrService } from '../services/ocr.service.js';
import { KycStockageService } from '../services/kyc-stockage.service.js';

@Injectable()
export class ExtraireDonneesCniService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ocr: OcrService,
    private readonly kycStockage: KycStockageService,
  ) {}

  /**
   * Lance l'OCR sur la CNI recto et retourne les données extraites.
   * Le frontend affiche ces données pour validation par l'utilisateur.
   * Rien n'est enregistré en base à cette étape.
   */
  async executer(utilisateurId: string) {
    const vendeur = await this.prisma.vendeur.findUnique({
      where: { id: utilisateurId },
      select: {
        dossiersKyc: {
          orderBy: { dateSoumission: 'desc' },
          take: 1,
          select: {
            id: true,
            statut: true,
            documents: {
              where: { typeDocument: 'CNI_RECTO' },
              select: { cleStockage: true },
              take: 1,
            },
          },
        },
      },
    });

    if (!vendeur) throw new ForbiddenException('Profil vendeur introuvable.');

    const dossier = vendeur.dossiersKyc[0];
    if (!dossier) throw new NotFoundException('Dossier KYC introuvable.');

    const documentCniRecto = dossier.documents[0];
    if (!documentCniRecto) {
      throw new NotFoundException(
        'CNI recto non uploadée. Uploadez d\'abord la CNI recto.',
      );
    }

    const imageBuffer = await this.kycStockage.getFile(documentCniRecto.cleStockage);
    if (!imageBuffer) {
      throw new NotFoundException('Image CNI non trouvée.');
    }

    const donnees = await this.ocr.extraireDonneesCni(imageBuffer);

    return {
      donnees,
      avertissement:
        donnees.confidence < 70
          ? 'La qualité de l\'image est faible. Veuillez vérifier soigneusement les informations extraites.'
          : null,
    };
  }
}