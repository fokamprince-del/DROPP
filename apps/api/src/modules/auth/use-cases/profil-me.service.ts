import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';

@Injectable()
export class ProfilMeService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(utilisateurId: string) {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: {
        id: true,
        prenom: true,
        nom: true,
        email: true,
        emailVerifieLe: true,
        telephone: true,
        telephoneVerifieLe: true,
        statutCompte: true,
        dateInscription: true,
        derniereConnexion: true,
        client: { select: { statutClient: true } },
        vendeur: { select: { statutVendeur: true } },
      },
    });

    if (!utilisateur) throw new NotFoundException('Utilisateur introuvable.');

    return {
      id: utilisateur.id,
      prenom: utilisateur.prenom,
      nom: utilisateur.nom,
      email: utilisateur.email,
      emailVerifie: utilisateur.emailVerifieLe !== null,
      telephone: utilisateur.telephone,
      telephoneVerifie: utilisateur.telephoneVerifieLe !== null,
      statutCompte: utilisateur.statutCompte,
      dateInscription: utilisateur.dateInscription,
      derniereConnexion: utilisateur.derniereConnexion,
      estClient: utilisateur.client !== null,
      statutClient: utilisateur.client?.statutClient ?? null,
      estVendeur: utilisateur.vendeur !== null,
      statutVendeur: utilisateur.vendeur?.statutVendeur ?? null,
    };
  }
}