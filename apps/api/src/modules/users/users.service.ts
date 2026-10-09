import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { estPseudoReserve, FORMAT_PSEUDO, normaliserPseudo } from './pseudo.js';

import { PrismaService } from '../../infrastructure/database/prisma.service.js';
import {
  TAILLE_MAX_IMAGE_MO,
  TYPES_MIME_IMAGE,
  type SignatureImageDto,
} from '../../infrastructure/stockage/image.dto.js';
import { verifierUpload } from '../../infrastructure/stockage/verifier-upload.js';
import {
  STOCKAGE_PROVIDER,
  type StockageProvider,
} from '../../infrastructure/stockage/stockage-provider.contract.js';
import { MiseAJourProfilDto } from './dto/mise-a-jour-profil.dto.js';

const profilSelection = {
  id: true,
  nom: true,
  prenom: true,
  pseudo: true,
  email: true,
  telephone: true,
  photoProfilCle: true,
  sexe: true,
  dateInscription: true,
  statutCompte: true,
  derniereConnexion: true,
  client: {
    select: {
      statutClient: true,
    },
  },
  vendeur: {
    select: {
      statutVendeur: true,
      biographie: true,
      boutique: {
        select: {
          id: true,
          nom: true,
          statut: true,
        },
      },
    },
  },
  roles: {
    select: {
      role: {
        select: {
          nom: true,
        },
      },
    },
  },
} as const;

type ProfilBrut = {
  photoProfilCle: string | null;
} & Record<string, unknown>;

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(STOCKAGE_PROVIDER) private readonly stockage: StockageProvider,
  ) {}

  async obtenirProfil(utilisateurId: string) {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: profilSelection,
    });

    if (!utilisateur) {
      throw new NotFoundException('Utilisateur introuvable.');
    }

    return this.presenter(utilisateur);
  }

  async mettreAJourProfil(utilisateurId: string, dto: MiseAJourProfilDto) {
    const existe = await this.prisma.utilisateur.count({
      where: { id: utilisateurId },
    });
    if (!existe) throw new NotFoundException('Utilisateur introuvable.');
    if (dto.pseudo && estPseudoReserve(dto.pseudo)) {
      throw new BadRequestException('Ce pseudo est réservé.');
    }

    try {
      const utilisateur = await this.prisma.utilisateur.update({
        where: { id: utilisateurId },
        data: {
          nom: dto.nom,
          prenom: dto.prenom,
          pseudo: dto.pseudo,
          sexe: dto.sexe,
        },
        select: profilSelection,
      });
      return this.presenter(utilisateur);
    } catch (e) {
      if (
        typeof e === 'object' &&
        e !== null &&
        'code' in e &&
        (e as { code: string }).code === 'P2002'
      ) {
        throw new ConflictException('Ce pseudo est déjà pris.');
      }
      throw e;
    }
  }

  async pseudoDisponible(brut: string) {
    const pseudo = normaliserPseudo(brut);
    if (!FORMAT_PSEUDO.test(pseudo) || estPseudoReserve(pseudo)) {
      return { pseudo, disponible: false };
    }
    const pris = await this.prisma.utilisateur.count({ where: { pseudo } });
    return { pseudo, disponible: pris === 0 };
  }

  // ── Photo de profil ───────────────────────────────────────────────────────

  signaturePhoto(utilisateurId: string, dto: SignatureImageDto) {
    return this.stockage.genererSignatureUpload(
      this.repertoirePhoto(utilisateurId),
      dto.typeMime,
      TAILLE_MAX_IMAGE_MO,
    );
  }

  async confirmerPhoto(utilisateurId: string, cleStockage: string) {
    await verifierUpload(this.stockage, {
      cleStockage,
      prefixe: this.repertoirePhoto(utilisateurId),
      tailleMaxMo: TAILLE_MAX_IMAGE_MO,
      typesMime: TYPES_MIME_IMAGE,
    });
    return this.remplacerPhoto(utilisateurId, cleStockage);
  }

  supprimerPhoto(utilisateurId: string) {
    return this.remplacerPhoto(utilisateurId, null);
  }

  private async remplacerPhoto(utilisateurId: string, cle: string | null) {
    const avant = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: { photoProfilCle: true },
    });
    if (!avant) throw new NotFoundException('Utilisateur introuvable.');

    const utilisateur = await this.prisma.utilisateur.update({
      where: { id: utilisateurId },
      data: { photoProfilCle: cle },
      select: profilSelection,
    });

    if (avant.photoProfilCle && avant.photoProfilCle !== cle) {
      await this.stockage.supprimer(avant.photoProfilCle).catch(() => undefined);
    }
    return this.presenter(utilisateur);
  }

  private repertoirePhoto(utilisateurId: string) {
    return `utilisateurs/${utilisateurId}/profil`;
  }

  private presenter<T extends ProfilBrut>(utilisateur: T) {
    const { photoProfilCle, ...reste } = utilisateur;
    return {
      ...reste,
      photoProfilUrl: photoProfilCle
        ? this.stockage.urlPublique(photoProfilCle, {
            largeur: 400,
            hauteur: 400,
          })
        : null,
    };
  }
}
