import {
  ConflictException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';

import type { StatutCommande } from '@dropp/database';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../../infrastructure/stockage/stockage-provider.contract.js';
import type { SupprimerCompteDto } from '../dto/changement-telephone.dto.js';
import { MotDePasseService } from '../services/mot-de-passe.service.js';

/** Commandes qui empêchent la suppression tant qu'elles ne sont pas terminées. */
const STATUTS_EN_COURS: StatutCommande[] = [
  'EN_ATTENTE_PAIEMENT',
  'NOUVELLE',
  'EN_COURS',
  'EXPEDIEE',
  'EN_LITIGE',
];

/**
 * Suppression de compte (exigée par l'App Store et le Play Store).
 *
 * Le compte est ANONYMISÉ plutôt qu'effacé : les commandes, paiements et
 * écritures comptables doivent être conservés (obligations légales), et les
 * contraintes de la table utilisateurs imposent un email ou un téléphone —
 * d'où l'email technique non routable « supprime-<id>@supprime.invalid ».
 */
@Injectable()
export class SuppressionCompteService {
  private readonly logger = new Logger(SuppressionCompteService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly motDePasse: MotDePasseService,
    @Inject(STOCKAGE_PROVIDER) private readonly stockage: StockageProvider,
  ) {}

  async executer(
    utilisateurId: string,
    dto: SupprimerCompteDto,
    adresseIp?: string,
  ): Promise<void> {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: {
        statutCompte: true,
        motDePasseHash: true,
        photoProfilCle: true,
        vendeur: {
          select: {
            boutique: { select: { logoCle: true, banniereCle: true } },
          },
        },
      },
    });
    if (!utilisateur || utilisateur.statutCompte === 'SUPPRIME') {
      throw new NotFoundException('Compte introuvable.');
    }

    if (utilisateur.motDePasseHash) {
      const { valide } = await this.motDePasse.verifier(
        dto.motDePasse ?? '',
        utilisateur.motDePasseHash,
      );
      if (!valide) throw new UnauthorizedException('Mot de passe incorrect.');
    }

    const [achats, ventes] = await Promise.all([
      this.prisma.commande.count({
        where: { utilisateurId, statut: { in: STATUTS_EN_COURS } },
      }),
      this.prisma.sousCommande.count({
        where: { vendeurId: utilisateurId, statut: { in: STATUTS_EN_COURS } },
      }),
    ]);
    if (achats + ventes > 0) {
      throw new ConflictException(
        'Des commandes sont encore en cours. Attendez leur livraison ou annulez-les avant de supprimer votre compte.',
      );
    }

    const maintenant = new Date();
    const id = utilisateurId;

    await this.prisma.$transaction([
      // Identité anonymisée
      this.prisma.utilisateur.update({
        where: { id },
        data: {
          statutCompte: 'SUPPRIME',
          prenom: 'Utilisateur',
          nom: 'supprimé',
          pseudo: null,
          email: `supprime-${id}@supprime.invalid`,
          emailVerifieLe: null,
          telephone: null,
          telephoneVerifieLe: null,
          motDePasseHash: null,
          photoProfilCle: null,
        },
      }),
      // Accès
      this.prisma.session.updateMany({
        where: { utilisateurId: id, dateRevocation: null },
        data: { dateRevocation: maintenant },
      }),
      this.prisma.appareil.deleteMany({ where: { utilisateurId: id } }),
      this.prisma.identiteExterne.deleteMany({ where: { utilisateurId: id } }),
      // Données personnelles et sociales
      this.prisma.adresse.deleteMany({ where: { clientId: id } }),
      this.prisma.notification.deleteMany({ where: { utilisateurId: id } }),
      this.prisma.preferenceNotification.deleteMany({ where: { utilisateurId: id } }),
      this.prisma.abonnement.deleteMany({
        where: { OR: [{ utilisateurId: id }, { vendeurId: id }] },
      }),
      this.prisma.favoriProduit.deleteMany({ where: { utilisateurId: id } }),
      this.prisma.favoriPublication.deleteMany({ where: { utilisateurId: id } }),
      this.prisma.aime.deleteMany({ where: { utilisateurId: id } }),
      this.prisma.aimeCommentaire.deleteMany({ where: { utilisateurId: id } }),
      this.prisma.partage.deleteMany({ where: { utilisateurId: id } }),
      this.prisma.vueStory.deleteMany({ where: { utilisateurId: id } }),
      this.prisma.blocage.deleteMany({
        where: { OR: [{ bloqueurId: id }, { bloqueId: id }] },
      }),
      this.prisma.commentaire.updateMany({
        where: { utilisateurId: id },
        data: { statut: 'SUPPRIME' },
      }),
      this.prisma.articlePanier.deleteMany({ where: { panier: { utilisateurId: id } } }),
      this.prisma.conversation.updateMany({
        where: { participants: { some: { utilisateurId: id } } },
        data: { statut: 'FERMEE' },
      }),
      this.prisma.client.updateMany({
        where: { id },
        data: { statutClient: 'SUSPENDU' },
      }),
      // Côté vendeur : boutique et contenus retirés
      this.prisma.vendeur.updateMany({
        where: { id },
        data: { statutVendeur: 'SUSPENDU', biographie: null },
      }),
      this.prisma.boutique.updateMany({
        where: { id },
        data: { statut: 'SUSPENDUE', logoCle: null, banniereCle: null },
      }),
      this.prisma.produit.updateMany({
        where: { boutiqueId: id },
        data: { statut: 'ARCHIVE' },
      }),
      this.prisma.publication.updateMany({
        where: { boutiqueId: id },
        data: { statut: 'SUPPRIMEE' },
      }),
      this.prisma.story.updateMany({
        where: { boutiqueId: id },
        data: { statut: 'SUPPRIMEE' },
      }),
      this.prisma.journalSecurite.create({
        data: { utilisateurId: id, evenement: 'COMPTE_SUPPRIME', adresseIp },
      }),
    ]);

    // Fichiers personnels : après la transaction (non bloquant).
    const fichiers = [
      utilisateur.photoProfilCle,
      utilisateur.vendeur?.boutique?.logoCle,
      utilisateur.vendeur?.boutique?.banniereCle,
    ].filter((c): c is string => Boolean(c));
    for (const cle of fichiers) {
      await this.stockage
        .supprimer(cle)
        .catch((e: unknown) => this.logger.warn(`Fichier ${cle} : ${String(e)}`));
    }
    // Médias des publications/stories : supprimés par le nettoyage périodique.
  }
}
