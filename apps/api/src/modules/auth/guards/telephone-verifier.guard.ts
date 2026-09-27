import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';

import { CLE_TELEPHONE_VERIFIE } from '../decorators/require-telephone-verifie.decorator.js';
import { UtilisateurConnecte } from '../types/utilisateur-connecte.js';

@Injectable()
export class TelephoneVerifieGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requis = this.reflector.getAllAndOverride<boolean>(
      CLE_TELEPHONE_VERIFIE,
      [context.getHandler(), context.getClass()],
    );

    if (!requis) return true;

    const request = context.switchToHttp().getRequest<Request>();
    const utilisateur = request.user as UtilisateurConnecte | undefined;

    if (!utilisateur?.telephoneVerifie) {
      throw new ForbiddenException(
        'Vérification du téléphone requise pour cette action.',
      );
    }

    return true;
  }
}
