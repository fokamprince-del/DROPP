import { BadRequestException, GatewayTimeoutException, Injectable, InternalServerErrorException, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { tryCatch } from 'bullmq';

export interface ResultatFaceMatch {
  score: number;
  correspondance: boolean;
  details?: string;
}

interface FacePlusPlusResponse {
  confidence?: number;
  thresholds?: {
    '1e-3'?: number;
    '1e-4'?: number;
    '1e-5'?: number;
  };
  faces1?: unknown[];
  faces2?: unknown[];
  request_id?: string;
  error_message?: string;
}

interface FaceComparisonResult {
  confidence: number; // Score normalisé entre 0 et 1
  thresholds: {
    '1e-3': number | null;
    '1e-4': number | null;
    '1e-5': number | null;
  };
}

/**
 * Stub Face++ — remplacer par l'implémentation réelle quand disponible.
 * https://www.faceplusplus.com/face-comparing/
 */
@Injectable()
export class FaceMatchService {
  private readonly logger = new Logger(FaceMatchService.name);
  private readonly apiUrl = 'https://api-us.faceplusplus.com/facepp/v3/compare';
  private readonly apiKey;
  private readonly apiSecret;

  constructor(config: ConfigService) {
    this.apiKey = config.getOrThrow('faceplusplus.apiKey');
    this.apiSecret = config.getOrThrow('faceplusplus.apiSecret');
  }

  async comparer(
  urlSelfie: string,
  urlCniRecto: string,
): Promise<ResultatFaceMatch> {
  const form = new FormData();

    form.append('api_key', this.apiKey);
    form.append('api_secret', this.apiSecret);
    form.append('image_url1', urlSelfie);
    form.append('image_url2', urlCniRecto);

    let response: Response;

    try {
      response = await fetch(this.apiUrl, {
        method: 'POST',
        body: form,
        signal: AbortSignal.timeout(15_000),
      });
    } catch (error) {
      if (
        error instanceof Error &&
        error.name === 'TimeoutError'
      ) {
        throw new GatewayTimeoutException(
          'Face verification timed out',
        );
      }

      throw new ServiceUnavailableException(
        'Face verification service unavailable',
      );
    }

    let data: FacePlusPlusResponse;

    try {
      data = await response.json() as FacePlusPlusResponse;
    } catch {
      throw new BadRequestException(
        'Invalid response from face provider',
      );
    }

    if (!response.ok || data.error_message) {
      const message = data.error_message ?? '';

      if (response.status === 401) {
        throw new InternalServerErrorException(
          'Face provider authentication failed',
        );
      }

      if (response.status === 403) {
        throw new ServiceUnavailableException(
          'Face provider access denied or quota exceeded',
        );
      }

      if (response.status === 429 ||
          message.includes('CONCURRENCY_LIMIT_EXCEEDED')) {
        throw new ServiceUnavailableException(
          'Face provider rate limit exceeded',
        );
      }

      if (
        message.includes('INVALID_IMAGE_URL') ||
        message.includes('IMAGE_ERROR') ||
        message.includes('INVALID_IMAGE_SIZE') ||
        message.includes('IMAGE_FILE_TOO_LARGE') ||
        message.includes('IMAGE_DOWNLOAD_TIMEOUT') ||
        message.includes('NO_FACE')
      ) {
        throw new BadRequestException(
          'Invalid image or no usable face detected',
        );
      }

      throw new ServiceUnavailableException(
        'Face comparison failed',
      );
    }

    if (
      typeof data.confidence !== 'number' ||
      !Number.isFinite(data.confidence) ||
      data.confidence < 0 ||
      data.confidence > 100
    ) {
      throw new BadRequestException(
        'No valid face comparison score returned',
      );
    }

    const confidence = data.confidence / 100;

    const normalizeThreshold = (
      value?: number,
    ): number | null =>
      typeof value === 'number' &&
      Number.isFinite(value) &&
      value >= 0 &&
      value <= 100
        ? value / 100
        : null;

    const threshold = normalizeThreshold(
      data.thresholds?.['1e-4'],
    );

    return {
      score: confidence,
      correspondance: this.evaluateFaceMatch({
        confidence,
        thresholds: {
          '1e-3': normalizeThreshold(
            data.thresholds?.['1e-3'],
          ),
          '1e-4': threshold,
          '1e-5': normalizeThreshold(
            data.thresholds?.['1e-5'],
          ),
        }
      }),
      details: data.request_id ?? 'Unknown request ID',
    };
  }

  private evaluateFaceMatch(
    result: FaceComparisonResult,
  ): boolean {
    const { confidence, thresholds } = result;

    if (
      !Number.isFinite(confidence) ||
      confidence < 0 ||
      confidence > 1
    ) {
      throw new Error('Invalid confidence score');
    }

    const threshold = thresholds['1e-4'];

    if (
      threshold === null ||
      !Number.isFinite(threshold) ||
      threshold < 0 ||
      threshold > 1
    ) {
      return true;
    }

    if (confidence >= threshold) {
      return true;
    }

    const lowerThreshold = thresholds['1e-3'];

    if (
      lowerThreshold !== null &&
      Number.isFinite(lowerThreshold) &&
      confidence < lowerThreshold
    ) {
      return false;
    }

    return true;
  }
}