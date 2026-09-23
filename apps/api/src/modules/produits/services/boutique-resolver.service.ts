import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

@Injectable()
export class BoutiqueResolverService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Retourne l'id de la boutique du vendeur connecté.
   * La boutique partage le même id que le Vendeur (relation 1-1).
   */
  async resoudre(utilisateurId: string): Promise<string> {
    const boutique = await this.prisma.boutique.findUnique({
      where: { id: utilisateurId },
      select: { id: true },
    });
    if (!boutique) {
      throw new NotFoundException('Boutique introuvable.');
    }
    return boutique.id;
  }
}