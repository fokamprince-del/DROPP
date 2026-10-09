import {
  BadRequestException,
  CallHandler,
  ConflictException,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request, Response } from 'express';
import { createHash } from 'node:crypto';
import { Observable, catchError, from, switchMap, throwError } from 'rxjs';

import { CLE_IDEMPOTENCE_REQUISE } from './idempotence.decorator.js';
import { IdempotenceService } from './idempotence.service.js';

export const IDEMPOTENCY_KEY_HEADER = 'idempotency-key';

@Injectable()
export class IdempotenceInterceptor implements NestInterceptor {
  constructor(
    private readonly idempotenceService: IdempotenceService,
    private readonly reflector: Reflector,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') return next.handle();

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

    if (idempotenceRequise) {
      if (!idempotencyKey || typeof idempotencyKey !== 'string') {
        throw new BadRequestException(
          'Le header Idempotency-Key est obligatoire pour cette route.',
        );
      }
    }

    // Pas de clé et pas obligatoire : on laisse passer normalement
    if (!idempotencyKey || typeof idempotencyKey !== 'string') {
      return next.handle();
    }
    if (idempotencyKey.length < 8 || idempotencyKey.length > 128) {
      throw new BadRequestException(
        'Idempotency-Key invalide : entre 8 et 128 caractères.',
      );
    }

    // La clé est cloisonnée par utilisateur, par route ET par contenu :
    // - deux clients envoyant la même clé ne reçoivent pas la réponse l'un de
    //   l'autre (route anonyme comprise : il faudrait aussi deviner le corps) ;
    // - la même clé avec un autre corps est une autre requête.
    // Les guards s'exécutent avant les interceptors : request.user est déjà posé.
    const utilisateur = request.user as { id?: string } | undefined;
    const empreinte = createHash('sha256')
      .update(JSON.stringify(request.body ?? {}))
      .digest('hex');
    const cle = createHash('sha256')
      .update(
        `${utilisateur?.id ?? 'anonyme'}:${request.method}:${request.baseUrl}${request.path}:${idempotencyKey}:${empreinte}`,
      )
      .digest('hex');

    return from(this.traiter(cle, response, next)).pipe(
      switchMap((result) => result),
    );
  }

  private async traiter(
    cle: string,
    response: Response,
    next: CallHandler,
  ): Promise<Observable<unknown>> {
    // 1. Réponse déjà calculée : la rejouer
    const cache = await this.idempotenceService.lire(cle);
    if (cache) {
      response.status(cache.statusCode);
      return from([cache.body]);
    }

    // 2. Marquer comme en cours (SET NX : une seule requête passe)
    const acquis = await this.idempotenceService.marquerEnCours(cle);
    if (!acquis) {
      throw new ConflictException(
        'Une requête identique est déjà en cours de traitement.',
      );
    }

    // 3. Exécuter et stocker ; en cas d'erreur, libérer la clé pour
    //    permettre un nouvel essai immédiat.
    return next.handle().pipe(
      switchMap((body) =>
        from(
          this.idempotenceService.stocker(cle, {
            statusCode: response.statusCode,
            body,
          }),
        ).pipe(switchMap(() => from([body]))),
      ),
      catchError((erreur: unknown) =>
        from(this.idempotenceService.liberer(cle)).pipe(
          switchMap(() => throwError(() => erreur)),
        ),
      ),
    );
  }
}
