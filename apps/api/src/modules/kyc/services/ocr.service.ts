import {
  Injectable,
  Logger,
  ServiceUnavailableException,
  type OnModuleDestroy,
} from '@nestjs/common';
import { createWorker, type Worker } from 'tesseract.js';

export interface DonneesCniExtraites {
  nomLegal?: string;
  prenomLegal?: string;
  numeroCni?: string;
  dateNaissance?: string;
  lieuNaissance?: string;
  dateEtablissement?: string;
  dateExpiration?: string;
  confidence: number; // 0 à 100
}

/** Au-delà, l'OCR est refusé (503) : protège le CPU de l'API. */
const MAX_EN_ATTENTE = 5;

/**
 * OCR des CNI avec Tesseract.js (français).
 * Un seul worker, créé à la première utilisation et réutilisé : les
 * reconnaissances sont exécutées l'une après l'autre, avec une file bornée,
 * pour qu'un afflux de demandes ne sature pas le processus de l'API.
 */
@Injectable()
export class OcrService implements OnModuleDestroy {
  private readonly logger = new Logger(OcrService.name);
  private worker?: Promise<Worker>;
  private file: Promise<unknown> = Promise.resolve();
  private enAttente = 0;

  async extraireDonneesCni(imageBuffer: Buffer): Promise<DonneesCniExtraites> {
    if (this.enAttente >= MAX_EN_ATTENTE) {
      throw new ServiceUnavailableException(
        'Lecture automatique momentanément indisponible. Saisissez vos informations ou réessayez dans un instant.',
      );
    }
    this.enAttente++;
    const tache = this.file.then(() => this.reconnaitre(imageBuffer));
    this.file = tache.catch(() => undefined);
    try {
      return await tache;
    } finally {
      this.enAttente--;
    }
  }

  async onModuleDestroy(): Promise<void> {
    const worker = await this.worker?.catch(() => undefined);
    await worker?.terminate();
  }

  private async reconnaitre(imageBuffer: Buffer): Promise<DonneesCniExtraites> {
    const worker = await this.obtenirWorker();
    const { data } = await worker.recognize(imageBuffer);
    this.logger.debug(`OCR terminé. Confiance : ${data.confidence}%.`);
    return { ...this.parserTexteCni(data.text), confidence: data.confidence };
  }

  private obtenirWorker(): Promise<Worker> {
    this.worker ??= createWorker('fra', 1, {
      logger: () => undefined, // Silencer les logs Tesseract
    }).catch((erreur: unknown) => {
      this.worker = undefined; // nouvel essai à la prochaine demande
      throw erreur;
    });
    return this.worker;
  }

  /**
   * Tente de parser le texte OCR pour extraire les champs de la CNI.
   * Les résultats sont approximatifs et doivent être validés par l'utilisateur.
   */
  private parserTexteCni(texte: string): Omit<DonneesCniExtraites, 'confidence'> {
    const lignes = texte
      .split('\n')
      .map((l) => l.trim())
      .filter((l) => l.length > 0);

    const resultat: Omit<DonneesCniExtraites, 'confidence'> = {};

    for (const ligne of lignes) {
      // Numéro CNI camerounaise : format variable, souvent 6-9 chiffres
      if (/^\d{6,9}$/.test(ligne)) {
        resultat.numeroCni = ligne;
      }

      // Dates : format DD/MM/YYYY ou DD-MM-YYYY
      const dateMatch = ligne.match(/(\d{2}[/-]\d{2}[/-]\d{4})/g);
      if (dateMatch?.length) {
        if (!resultat.dateNaissance) {
          resultat.dateNaissance = dateMatch[0];
        } else if (!resultat.dateEtablissement) {
          resultat.dateEtablissement = dateMatch[0];
        } else if (!resultat.dateExpiration) {
          resultat.dateExpiration = dateMatch[0];
        }
      }

      // Lieu de naissance : après "Né(e) à" ou "Lieu"
      const lieuMatch = ligne.match(/(?:né\(?e\)? à|lieu\s*:?)\s*(.+)/i);
      if (lieuMatch) {
        resultat.lieuNaissance = lieuMatch[1].trim();
      }
    }

    return resultat;
  }
}
