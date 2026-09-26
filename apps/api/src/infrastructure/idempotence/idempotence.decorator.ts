import { SetMetadata } from '@nestjs/common';

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
  SetMetadata(CLE_IDEMPOTENCE_REQUISE, true);