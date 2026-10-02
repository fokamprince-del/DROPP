import { Injectable, Logger } from '@nestjs/common';
import { createWorker } from 'tesseract.js';

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

@Injectable()
export class OcrService {
  private readonly logger = new Logger(OcrService.name);

  /**
   * Extrait les données textuelles d'une image de CNI.
   * Utilise Tesseract.js en mode français.
   * Résultat à valider obligatoirement par l'utilisateur.
   */
  async extraireDonneesCni(
    imageBuffer: Buffer,
  ): Promise<DonneesCniExtraites> {
    const worker = await createWorker('fra', 1, {
      logger: () => undefined, // Silencer les logs Tesseract
    });

    try {
      const { data } = await worker.recognize(imageBuffer);
      const texte = data.text;
      const confidence = data.confidence;

      this.logger.debug(
        `OCR terminé. Confiance: ${confidence}%. Texte extrait: ${texte.slice(0, 100)}...`,
      );

      return {
        ...this.parserTexteCni(texte),
        confidence,
      };
    } finally {
      await worker.terminate();
    }
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
      const dateMatch = ligne.match(/(\d{2}[\/\-]\d{2}[\/\-]\d{4})/g);
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