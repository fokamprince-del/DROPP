import {
  BadRequestException,
  CallHandler,
  ConflictException,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { Observable, from, switchMap, tap } from 'rxjs';

import { IdempotenceService } from './idempotence.service.js';
import { Reflector } from '@nestjs/core';
import { CLE_IDEMPOTENCE_REQUISE } from './idempotence.decorator.js';

export const IDEMPOTENCY_KEY_HEADER = 'idempotency-key';

@Injectable()
export class IdempotenceInterceptor implements NestInterceptor {
  constructor(
    private readonly idempotenceService: IdempotenceService,
    private readonly reflector: Reflector,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();
    const response = context.switchToHttp().getResponse<Response>();

    // Uniquement sur les POST
    if (request.method !== 'POST') {
      return next.handle();
    }

    const idempotenceRequise = this.reflector.getAllAndOverride<boolean>(
      CLE_IDEMPOTENCE_REQUISE,
      [context.getHandler(), context.getClass()],
    );

    const idempotencyKey = request.headers[IDEMPOTENCY_KEY_HEADER];

    // Si pas de clé, on laisse passer normalement
    if (idempotenceRequise) {
      if (!idempotencyKey || typeof idempotencyKey !== 'string') {
        throw new BadRequestException(
          'Le header Idempotency-Key est obligatoire pour cette route.',
        );
      }
      if (idempotencyKey.length < 8 || idempotencyKey.length > 128) {
        throw new BadRequestException(
          'Idempotency-Key invalide : entre 8 et 128 caractères.',
        );
      }
    }

    // Pas de clé et pas obligatoire : on laisse passer normalement
    if (!idempotencyKey || typeof idempotencyKey !== 'string') {
      return next.handle();
    }

    return from(this.traiter(idempotencyKey, response, next)).pipe(
      switchMap((result) => result),
    );
  }

  private async traiter(
    key: string,
    response: Response,
    next: CallHandler,
  ): Promise<Observable<unknown>> {
    // 1. Lire le cache
    const cache = await this.idempotenceService.lire(key);

    if (cache) {
      if ((cache as unknown as string) === 'PENDING') {
        throw new ConflictException(
          'Une requête identique est déjà en cours de traitement.',
        );
      }
      response.status(cache.statusCode);
      return from([cache.body]);
    }

    // Vérifier PENDING séparément
    const brut = await this.idempotenceService.lireBrut(key);
    if (brut === 'PENDING') {
      throw new ConflictException(
        'Une requête identique est déjà en cours de traitement.',
      );
    }

    // 2. Marquer comme en cours
    const acquis = await this.idempotenceService.marquerEnCours(key);
    if (!acquis) {
      throw new ConflictException(
        'Une requête identique est déjà en cours de traitement.',
      );
    }

    // 3. Exécuter et stocker
    return next.handle().pipe(
      tap(async (body) => {
        const statusCode = response.statusCode;
        await this.idempotenceService.stocker(key, { statusCode, body });
      }),
    );
  }
}
