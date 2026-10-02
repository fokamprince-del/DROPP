import { Injectable, Logger } from '@nestjs/common';

export interface ResultatFaceMatch {
  score: number;
  correspondance: boolean;
  details?: string;
}

/**
 * Stub Face++ — remplacer par l'implémentation réelle quand disponible.
 * https://www.faceplusplus.com/face-comparing/
 */
@Injectable()
export class FaceMatchService {
  private readonly logger = new Logger(FaceMatchService.name);

  async comparer(
    cleStockageSelfie: string,
    cleStockageCniRecto: string,
  ): Promise<ResultatFaceMatch> {
    this.logger.debug(
      `[FACE MATCH STUB] ${cleStockageSelfie} ↔ ${cleStockageCniRecto}`,
    );

    // Stub : simule un score élevé
    return {
      score: 0.92,
      correspondance: true,
      details: '[STUB] Vérification simulée',
    };
  }
}