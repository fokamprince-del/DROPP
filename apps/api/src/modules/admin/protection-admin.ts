import { BadRequestException, ForbiddenException } from '@nestjs/common';

import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import { ROLE } from '../auth/roles.js';

/**
 * Garde-fous des actions d'administration sur un compte :
 * - personne n'agit sur son propre compte ;
 * - un SUPER_ADMIN n'est jamais visé (retirer d'abord son rôle) ;
 * - seul un SUPER_ADMIN peut viser un autre membre de l'équipe.
 */
export async function verifierCibleAdministrable(
  prisma: PrismaService,
  acteurId: string,
  cibleId: string,
): Promise<void> {
  if (acteurId === cibleId) {
    throw new BadRequestException('Action impossible sur votre propre compte.');
  }

  const [rolesCible, acteurSuperAdmin] = await Promise.all([
    prisma.utilisateurRole.findMany({
      where: { utilisateurId: cibleId },
      select: { role: { select: { nom: true } } },
    }),
    prisma.utilisateurRole.count({
      where: { utilisateurId: acteurId, role: { nom: ROLE.SUPER_ADMIN } },
    }),
  ]);
  const noms = rolesCible.map((r) => r.role.nom);

  if (noms.includes(ROLE.SUPER_ADMIN)) {
    throw new ForbiddenException(
      'Un super administrateur ne peut pas être visé. Retirez d’abord son rôle.',
    );
  }
  if (noms.length > 0 && acteurSuperAdmin === 0) {
    throw new ForbiddenException(
      'Seul un super administrateur peut agir sur un membre de l’équipe.',
    );
  }
}
