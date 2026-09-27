import { NotFoundException } from '@nestjs/common';
import { StatutPublication } from '@dropp/database';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

export async function verifierPublicationVisible(
  prisma: PrismaService,
  publicationId: string,
) {
  const publication = await prisma.publication.findFirst({
    where: {
      id: publicationId,
      statut: StatutPublication.PUBLIEE,
      visibilite: 'PUBLIC',
      boutique: { statut: 'ACTIVE' },
    },
    select: { id: true, boutiqueId: true },
  });
  if (!publication) throw new NotFoundException('Publication introuvable.');
  return publication;
}
