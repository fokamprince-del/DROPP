import { Logger } from '@nestjs/common';
import type { Redis } from 'ioredis';

const logger = new Logger('Revocation');

export const cleRevocationUtilisateur = (utilisateurId: string) =>
  `dropp:revocation:utilisateur:${utilisateurId}`;

export const cleRevocationSession = (sessionId: string) =>
  `dropp:revocation:session:${sessionId}`;

/**
 * Vrai si le jeton d'accès a été révoqué avant son expiration :
 * - sa session a été fermée (déconnexion, session révoquée) ;
 * - ou tous les jetons de l'utilisateur émis avant une date donnée ont été
 *   invalidés (suspension, suppression, changement de mot de passe…).
 *
 * Redis indisponible : le jeton est accepté (il expire de toute façon en
 * 15 min) plutôt que de bloquer toute l'API.
 */
export async function jetonRevoque(
  redis: Redis,
  jeton: { sub: string; sid?: string; iat?: number },
): Promise<boolean> {
  try {
    const [depuis, session] = await redis.mget(
      cleRevocationUtilisateur(jeton.sub),
      jeton.sid ? cleRevocationSession(jeton.sid) : cleRevocationSession('-'),
    );
    if (session) return true;
    return depuis !== null && (jeton.iat ?? 0) < Number(depuis);
  } catch (erreur) {
    logger.warn(`Vérification de révocation impossible : ${String(erreur)}`);
    return false;
  }
}
