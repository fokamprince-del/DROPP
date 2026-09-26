import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { MotDePasseService } from '../services/mot-de-passe.service.js';
import { JetonService, type JetonsEmis } from '../services/jeton.service.js';
import type { ConnexionDto } from '../dto/connexion.dto.js';
import { OtpService } from '../services/otp.service.js';
import { NotificationService } from '../services/notification.service.js';
import type { PayloadVerification } from '../services/jeton.service.js';
import type { CanalVerification } from '../../../generated/prisma/enums.js';

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
    private readonly otpService: OtpService,             
  private readonly notificationService: NotificationService,
  ) {}

  /**
   * Connexion par email OU téléphone + mot de passe.
   * Réponse neutre si identifiant inconnu (anti-énumération).
   */
  async executer(
    dto: ConnexionDto,
    adresseIp?: string,
  ): Promise<JetonsEmis | { verificationRequise: true; verificationToken: string }> {
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
        email: true,
        telephone: true,
      },
    });

    if (!utilisateur || !utilisateur.motDePasseHash) {
      await this.motDePasseService
        .verifier(dto.motDePasse, '$argon2id$v=19$m=65536,t=3,p=4$factice$aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
        .catch(() => undefined);
      throw new UnauthorizedException('Identifiant ou mot de passe incorrect.');
    }

    const { valide, nouveauHash } = await this.motDePasseService.verifier(
      dto.motDePasse,
      utilisateur.motDePasseHash,
    );

    if (!valide) {
      throw new UnauthorizedException('Identifiant ou mot de passe incorrect.');
    }

    // Compte non vérifié : renvoyer un token de vérification
    if (utilisateur.statutCompte === 'EN_ATTENTE_VERIFICATION') {
      const canal: CanalVerification = utilisateur.email ? 'EMAIL' : 'SMS';
      const destination = canal === 'EMAIL'
        ? utilisateur.email!
        : utilisateur.telephone!;

      const { code } = await this.otpService.generer({
        destination,
        canal,
        type: 'INSCRIPTION',
        utilisateurId: utilisateur.id,
      });

      this.notificationService.envoyerOtp({
        destination,
        canal,
        code,
        type: 'inscription',
      });

      const verificationToken = this.jetonService.signerVerification({
        sub: utilisateur.id,
        dst: destination,
        canalOtp: canal,
        purpose: 'inscription',
      });

      return { verificationRequise: true, verificationToken };
    }

    if (!STATUTS_CONNEXION.has(utilisateur.statutCompte)) {
      throw new ForbiddenException('Compte indisponible.');
    }

    // Re-hachage transparent
    if (nouveauHash) {
      await this.prisma.utilisateur.update({
        where: { id: utilisateur.id },
        data: { motDePasseHash: nouveauHash },
      });
    }

    this.prisma.utilisateur
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
