import { NotFoundException } from '@nestjs/common';
import { StatutPublication, type Prisma } from '@dropp/database';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

/**
 * Règle de visibilité d'une publication, partagée par le fil, la page
 * publication, les likes, commentaires, favoris et partages :
 * - publiée et boutique active ;
 * - PUBLIC : visible de tous ;
 * - ABONNES : visible des abonnés actifs de la boutique et de la boutique elle-même.
 */
export function filtreVisibilite(
  utilisateurId?: string,
): Prisma.PublicationWhereInput {
  return {
    statut: StatutPublication.PUBLIEE,
    boutique: { statut: 'ACTIVE' },
    OR: [
      { visibilite: 'PUBLIC' },
      ...(utilisateurId
        ? [
            { boutiqueId: utilisateurId },
            {
              visibilite: 'ABONNES' as const,
              boutique: {
                vendeur: {
                  abonnements: { some: { utilisateurId, statut: 'ACTIF' as const } },
                },
              },
            },
          ]
        : []),
    ],
  };
}

/**
 * Retourne la publication si l'utilisateur (ou un visiteur anonyme) peut la
 * voir, sinon 404 — y compris en cas de blocage entre lui et la boutique.
 */
export async function verifierPublicationVisible(
  prisma: PrismaService,
  publicationId: string,
  utilisateurId?: string,
) {
  const publication = await prisma.publication.findFirst({
    where: { id: publicationId, ...filtreVisibilite(utilisateurId) },
    select: { id: true, boutiqueId: true, visibilite: true },
  });
  if (!publication) throw new NotFoundException('Publication introuvable.');

  if (utilisateurId && utilisateurId !== publication.boutiqueId) {
    const bloque = await prisma.blocage.count({
      where: {
        OR: [
          { bloqueurId: publication.boutiqueId, bloqueId: utilisateurId },
          { bloqueurId: utilisateurId, bloqueId: publication.boutiqueId },
        ],
      },
    });
    if (bloque > 0) throw new NotFoundException('Publication introuvable.');
  }
  return publication;
}
