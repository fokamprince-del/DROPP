import { applyDecorators } from '@nestjs/common';
import { ApiResponse } from '@nestjs/swagger';
import { ErreurApiDto } from './erreur-api.dto.js';

const DESCRIPTIONS: Record<number, string> = {
  400: 'Requête invalide.',
  401: 'Identifiants ou jeton invalides.',
  403: 'Accès refusé.',
  404: 'Ressource introuvable.',
  409: 'Conflit avec l’état actuel de la ressource.',
  410: 'Code expiré ou trop de tentatives : demandez-en un nouveau.',
};

/** @example @ApiErreurs(404, 409) */
export const ApiErreurs = (...codes: number[]) =>
  applyDecorators(
    ...codes.map((status) =>
      ApiResponse({ status, type: ErreurApiDto, description: DESCRIPTIONS[status] ?? 'Erreur.' }),
    ),
  );