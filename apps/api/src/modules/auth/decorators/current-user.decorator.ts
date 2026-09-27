import { createParamDecorator, type ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';

import { UtilisateurConnecte } from '../types/utilisateur-connecte.js';

/**
 * Injecte l'utilisateur connecté dans le paramètre de la méthode du contrôleur.
 *
 * @example
 * async maRoute(@CurrentUser() utilisateur: UtilisateurConnecte) { ... }
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): UtilisateurConnecte | undefined => {
    const request = ctx.switchToHttp().getRequest<Request>();
    return request.user as UtilisateurConnecte | undefined;
  },
);
