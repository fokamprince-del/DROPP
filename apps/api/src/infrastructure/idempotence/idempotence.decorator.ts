import { applyDecorators, SetMetadata } from '@nestjs/common';
import { ApiExtension, ApiHeader, ApiResponse } from '@nestjs/swagger';
import { ErreurApiDto } from '../http/erreur-api.dto.js';

export const CLE_IDEMPOTENCE_REQUISE = 'idempotence_requise';

/**
 * Marque une route POST comme nécessitant une Idempotency-Key.
 * Sans ce décorateur, l'interceptor laisse passer sans vérification.
 *
 * @example
 * @RequiertIdempotenceKey()
 * @Post('inscription')
 * inscrire(@Body() dto: InscriptionDto) { ... }
 */
export const RequiertIdempotenceKey = () =>
  applyDecorators(
    SetMetadata(CLE_IDEMPOTENCE_REQUISE, true),
    ApiExtension('x-idempotent', true),
    ApiHeader({
      name: 'Idempotency-Key',
      required: true,
      description:
        'UUID v4 généré une fois par action de l’utilisateur et réutilisé tel quel pour chaque nouvel essai. ' +
        'Rejouer la même clé pendant 24 h renvoie la réponse d’origine sans ré-exécuter l’action.',
      schema: { type: 'string', minLength: 8, maxLength: 128 },
    }),
    ApiResponse({
      status: 400,
      type: ErreurApiDto,
      description: 'Requête invalide, ou en-tête Idempotency-Key manquant ou invalide.',
    }),
    ApiResponse({
      status: 409,
      type: ErreurApiDto,
      description: 'Une requête avec la même clé est encore en cours de traitement.',
    }),
  );
  
