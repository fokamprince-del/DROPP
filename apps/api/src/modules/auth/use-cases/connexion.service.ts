import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { MotDePasseService } from '../services/mot-de-passe.service.js';
import { JetonService, type JetonsEmis } from '../services/jeton.service.js';
import type { ConnexionDto } from '../dto/connexion.dto.js';

/**
 * Statuts autorisant la connexion.
 * Tout autre statut (SUSPENDU_TEMP, SUSPENDU_DEF, SUPPRIME) est refusé.
 */
const STATUTS_CONNEXION = new Set(['EN_ATTENTE_VERIFICATION', 'ACTIF']);

@Injectable()
export class ConnexionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly motDePasseService: MotDePasseService,
    private readonly jetonService: JetonService,
  ) {}

  /**
   * Connexion par email OU téléphone + mot de passe.
   * Réponse neutre si identifiant inconnu (anti-énumération).
   */
  async executer(dto: ConnexionDto, adresseIp?: string): Promise<JetonsEmis> {
    // Détection automatique : email si contient @, sinon téléphone
    const estEmail = dto.identifiant.includes('@');
    const identifiantNormalise = estEmail
      ? dto.identifiant.trim().toLowerCase()
      : dto.identifiant.trim();

    const utilisateur = await this.prisma.utilisateur.findFirst({
      where: estEmail
        ? { email: identifiantNormalise }
        : { telephone: identifiantNormalise },
      select: {
        id: true,
        motDePasseHash: true,
        statutCompte: true,
        telephoneVerifieLe: true,
      },
    });

    // Réponse neutre : on hache quand même pour éviter les timing attacks
    if (!utilisateur || !utilisateur.motDePasseHash) {
      await this.motDePasseService.verifier(dto.motDePasse, '$argon2id$v=19$m=65536,t=3,p=4$factice');
      throw new UnauthorizedException('Identifiant ou mot de passe incorrect.');
    }

    const { valide, nouveauHash } = await this.motDePasseService.verifier(
      dto.motDePasse,
      utilisateur.motDePasseHash,
    );

    if (!valide) {
      throw new UnauthorizedException('Identifiant ou mot de passe incorrect.');
    }

    if (!STATUTS_CONNEXION.has(utilisateur.statutCompte)) {
      throw new ForbiddenException('Compte indisponible.');
    }

    // Re-hachage transparent si les paramètres ont évolué
    if (nouveauHash) {
      await this.prisma.utilisateur.update({
        where: { id: utilisateur.id },
        data: { motDePasseHash: nouveauHash },
      });
    }

    // Mise à jour de la date de dernière connexion (best-effort)
    void this.prisma.utilisateur
      .update({ where: { id: utilisateur.id }, data: { derniereConnexion: new Date() } })
      .catch(() => undefined);

    return this.jetonService.ouvrirSession({
      utilisateurId: utilisateur.id,
      statutCompte: utilisateur.statutCompte,
      telephoneVerifie: utilisateur.telephoneVerifieLe !== null,
      methodeAuth: estEmail ? 'EMAIL_MDP' : 'TELEPHONE_MDP',
      adresseIp,
    });
  }
}