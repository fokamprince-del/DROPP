import { Injectable, NotFoundException } from '@nestjs/common';

import type { StatutKyc } from '@dropp/database';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { DossierKycService } from '../services/dossier-kyc.service.js';
import { KycStockageService } from '../services/kyc-stockage.service.js';

@Injectable()
export class ConsulterDossierService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly kycStockage: KycStockageService,
    private readonly dossiers: DossierKycService,
  ) {}

  /** Vue vendeur : son dossier (créé si besoin), sans les fichiers. */
  async pourVendeur(utilisateurId: string) {
    const { id } = await this.dossiers.courant(utilisateurId);
    return this.prisma.dossierKyc.findUniqueOrThrow({
      where: { id },
      select: {
        id: true,
        statut: true,
        motifRejet: true,
        dateSoumission: true,
        dateValidation: true,
        dateRejet: true,
        consentementLe: true,
        nomLegal: true,
        prenomLegal: true,
        numeroCni: true,
        dateNaissance: true,
        lieuNaissance: true,
        dateEtablissement: true,
        dateExpiration: true,
        documents: {
          select: { id: true, typeDocument: true, statut: true, dateCreation: true },
        },
      },
    });
  }

  /** Vue admin : dossier complet avec URLs signées (5 min) pour consulter les pièces. */
  async pourAdmin(dossierKycId: string, adminId: string) {
    const dossier = await this.prisma.dossierKyc.findUnique({
      where: { id: dossierKycId },
      select: {
        id: true,
        statut: true,
        nomLegal: true,
        prenomLegal: true,
        numeroCni: true,
        dateNaissance: true,
        lieuNaissance: true,
        dateEtablissement: true,
        dateExpiration: true,
        scoreFaceMatch: true,
        motifRejet: true,
        consentementLe: true,
        dateSoumission: true,
        dateValidation: true,
        dateRejet: true,
        vendeur: {
          select: {
            id: true,
            statutVendeur: true,
            utilisateur: {
              select: { prenom: true, nom: true, telephone: true, email: true },
            },
            boutique: {
              select: { nom: true, ville: true, quartier: true },
            },
          },
        },
        documents: {
          select: {
            id: true,
            typeDocument: true,
            cleStockage: true,
            statut: true,
          },
        },
        verifications: {
          select: {
            typeVerification: true,
            statut: true,
            scoreMatching: true,
            commentaire: true,
            dateVerification: true,
          },
        },
        revues: {
          select: {
            statut: true,
            commentaire: true,
            dateRevue: true,
            administrateur: {
              select: { prenom: true, nom: true },
            },
          },
          orderBy: { dateRevue: 'desc' },
        },
      },
    });

    if (!dossier) throw new NotFoundException('Dossier KYC introuvable.');

    // Audit : chaque consultation de pièces d'identité est tracée.
    await this.prisma.journalAudit.create({
      data: {
        administrateurId: adminId,
        action: 'CONSULTER_DOSSIER_KYC',
        resourceType: 'DossierKyc',
        resourceId: dossierKycId,
      },
    });

    const documents = await Promise.all(
      dossier.documents.map(async ({ cleStockage, ...doc }) => ({
        ...doc,
        urlConsultation: await this.kycStockage.urlConsultation(cleStockage),
      })),
    );
    return { ...dossier, documents };
  }

  /** Liste des dossiers pour l'admin (les plus anciens d'abord). */
  async listerPourAdmin(params: {
    statut?: StatutKyc;
    page: number;
    limite: number;
  }) {
    const where = params.statut ? { statut: params.statut } : {};

    const [dossiers, total] = await this.prisma.$transaction([
      this.prisma.dossierKyc.findMany({
        where,
        select: {
          id: true,
          statut: true,
          scoreFaceMatch: true,
          dateSoumission: true,
          vendeur: {
            select: {
              utilisateur: {
                select: { prenom: true, nom: true, telephone: true },
              },
              boutique: { select: { nom: true } },
            },
          },
        },
        orderBy: { dateSoumission: 'asc' },
        skip: (params.page - 1) * params.limite,
        take: params.limite,
      }),
      this.prisma.dossierKyc.count({ where }),
    ]);

    return {
      donnees: dossiers,
      pagination: {
        total,
        page: params.page,
        limite: params.limite,
        pages: Math.ceil(total / params.limite),
      },
    };
  }
}
