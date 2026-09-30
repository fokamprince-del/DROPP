import {
  ArgumentsHost,
  Catch,
  HttpStatus,
  Logger,
  type ExceptionFilter,
} from '@nestjs/common';
import type { Response } from 'express';

import { Prisma } from '../../generated/prisma/client.js';

const CORRESPONDANCES: Record<string, { statut: HttpStatus; message: string }> = {
  P2002: { statut: HttpStatus.CONFLICT, message: 'Cette ressource existe déjà.' },
  P2025: { statut: HttpStatus.NOT_FOUND, message: 'Ressource introuvable.' },
  P2003: { statut: HttpStatus.BAD_REQUEST, message: 'Référence invalide.' },
};

/**
 * Filet de sécurité : les erreurs Prisma connues non gérées par les services
 * deviennent des 409/404/400 au lieu de 500. Les autres restent des 500.
 */
@Catch(Prisma.PrismaClientKnownRequestError)
export class PrismaExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrismaExceptionFilter.name);

  catch(erreur: Prisma.PrismaClientKnownRequestError, host: ArgumentsHost) {
    const reponse = host.switchToHttp().getResponse<Response>();
    const correspondance = CORRESPONDANCES[erreur.code];

    if (!correspondance) {
      this.logger.error(`Prisma ${erreur.code} : ${erreur.message}`);
      reponse.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: 'Erreur interne.',
      });
      return;
    }

    reponse.status(correspondance.statut).json({
      statusCode: correspondance.statut,
      message: correspondance.message,
    });
  }
}
