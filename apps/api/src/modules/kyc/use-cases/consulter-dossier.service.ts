import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { KycStockageService } from '../services/kyc-stockage.service.js';

@Injectable()
export class ConsulterDossierService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly kycStockage: KycStockageService,
  ) {}

  /** Vue vendeur : son propre dossier sans URLs signées. */
  async pourVendeur(utilisateurId: string) {
    const dossier = await this.prisma.dossierKyc.findFirst({
      where: { vendeurId: utilisateurId },
      orderBy: { dateSoumission: 'desc' },
      select: {
        id: true,
        statut: true,
        motifRejet: true,
        scoreFaceMatch: true,
        dateSoumission: true,
        documents: {
          select: { id: true, typeDocument: true, statut: true },
        },
      },
    });

    if (!dossier) throw new NotFoundException('Dossier KYC introuvable.');

    return dossier;
  }

  /** Vue admin : dossier complet avec URLs signées pour consulter les documents. */
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
        dateSoumission: true,
        dateValidation: true,
        dateRejet: true,
        vendeur: {
          select: {
            id: true,
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

    // Audit : log de la consultation
    await this.prisma.journalAudit.create({
      data: {
        administrateurId: adminId,
        action: 'CONSULTER_DOSSIER_KYC',
        resourceType: 'DossierKyc',
        resourceId: dossierKycId,
      },
    });

    // Enrichir avec URLs signées pour les documents (TTL 5 min)
    return {
      ...dossier,
      documents: dossier.documents.map((doc) => ({
        ...doc,
        urlConsultation: this.kycStockage.urlConsultation(doc.cleStockage),
      })),
    };
  }

  /** Liste des dossiers pour l'admin avec filtres. */
  async listerPourAdmin(params: {
    statut?: string;
    page: number;
    limite: number;
  }) {
    const where = params.statut ? { statut: params.statut as any } : {};

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
        pages: Math.ceil(total / params.limite),
      },
    };
  }
}