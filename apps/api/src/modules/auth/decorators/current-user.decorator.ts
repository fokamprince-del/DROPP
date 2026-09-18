import {
  createParamDecorator,
  ExecutionContext,
} from '@nestjs/common';

import { UtilisateurAuthentifie } from '../types/user-authentified.type.js';

export const UtilisateurCourant = createParamDecorator(
  (
    _data: unknown,
    context: ExecutionContext,
  ): UtilisateurAuthentifie => {
    const request = context
      .switchToHttp()
      .getRequest<{ user: UtilisateurAuthentifie }>();

    return request.user;
  },
);