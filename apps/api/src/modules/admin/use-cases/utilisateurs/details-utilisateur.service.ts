import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';

@Injectable()
export class DetailUtilisateurService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(utilisateurId: string, adminId: string) {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: {
        id: true,
        prenom: true,
        nom: true,
        telephone: true,
        email: true,
        sexe: true,
        statutCompte: true,
        dateInscription: true,
        derniereConnexion: true,
        telephoneVerifieLe: true,
        emailVerifieLe: true,
        client: { select: { statutClient: true, dateCreation: true } },
        vendeur: {
          select: {
            statutVendeur: true,
            numeroMobileMoney: true,
            operateurMobileMoney: true,
            boutique: { select: { id: true, nom: true, statut: true } },
            dossiersKyc: {
              orderBy: { dateSoumission: 'desc' },
              take: 1,
              select: { id: true, statut: true, dateSoumission: true },
            },
          },
        },
        roles: { select: { role: { select: { id: true, nom: true } } } },
        sessions: {
          where: { dateRevocation: null, dateExpiration: { gt: new Date() } },
          select: {
            id: true,
            methodeAuth: true,
            adresseIpCreation: true,
            dateCreation: true,
            dateDerniereUtilisation: true,
          },
          orderBy: { dateCreation: 'desc' },
          take: 5,
        },
      },
    });

    if (!utilisateur) throw new NotFoundException('Utilisateur introuvable.');

    // Audit
    await this.prisma.journalAudit.create({
      data: {
        administrateurId: adminId,
        action: 'CONSULTER_UTILISATEUR',
        resourceType: 'Utilisateur',
        resourceId: utilisateurId,
      },
    });

    return {
      ...utilisateur,
      roles: utilisateur.roles.map((r) => r.role),
    };
  }
}