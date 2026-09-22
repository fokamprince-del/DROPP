import { createParamDecorator, type ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';

import type { UtilisateurConnecte } from '../strategies/jwt.strategy.js';

/**
 * Injecte l'utilisateur connecté dans le paramètre de la méthode du contrôleur.
 *
 * @example
 * async maRoute(@CurrentUser() utilisateur: UtilisateurConnecte) { ... }
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): UtilisateurConnecte => {
    const request = ctx.switchToHttp().getRequest<Request>();
    return request.user as UtilisateurConnecte;
  },
);