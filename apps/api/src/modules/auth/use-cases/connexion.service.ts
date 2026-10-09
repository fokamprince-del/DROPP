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
import { TelephoneService } from '../services/telephone.service.js';
import { VerrouillageService } from '../services/verrouillage.service.js';

/**
 * Statuts autorisant la connexion.
 * Tout autre statut (SUSPENDU_TEMP, SUSPENDU_DEF, SUPPRIME) est refusé.
 */
const STATUTS_CONNEXION = new Set(['EN_ATTENTE_VERIFICATION', 'ACTIF']);

/** Hash argon2id factice : temps de réponse identique pour un compte inconnu. */
const HASH_FACTICE =
  '$argon2id$v=19$m=65536,t=3,p=4$factice$aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

@Injectable()
export class ConnexionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly motDePasseService: MotDePasseService,
    private readonly jetonService: JetonService,
    private readonly otpService: OtpService,
    private readonly notificationService: NotificationService,
    private readonly telephoneService: TelephoneService,
    private readonly verrouillage: VerrouillageService,
  ) {}

  /**
   * Connexion par email OU téléphone + mot de passe.
   * Réponse neutre si identifiant inconnu (anti-énumération).
   */
  async executer(
    dto: ConnexionDto,
    adresseIp?: string,
  ): Promise<
    JetonsEmis | { verificationRequise: true; verificationToken: string }
  > {
    const estEmail = dto.identifiant.includes('@');
    // « 650 00 00 01 » doit retrouver « +237650000001 » (format E.164 en base).
    const identifiantNormalise = estEmail
      ? dto.identifiant.trim().toLowerCase()
      : this.telephoneService.normaliserOuBrut(dto.identifiant);

    await this.verrouillage.verifier(identifiantNormalise);

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
        .verifier(dto.motDePasse, HASH_FACTICE)
        .catch(() => undefined);
      await this.verrouillage.echec(identifiantNormalise);
      throw new UnauthorizedException('Identifiant ou mot de passe incorrect.');
    }

    const { valide, nouveauHash } = await this.motDePasseService.verifier(
      dto.motDePasse,
      utilisateur.motDePasseHash,
    );

    if (!valide) {
      const verrouille = await this.verrouillage.echec(identifiantNormalise);
      await this.journaliser(
        utilisateur.id,
        verrouille ? 'COMPTE_VERROUILLE' : 'CONNEXION_ECHOUEE',
        adresseIp,
      );
      throw new UnauthorizedException('Identifiant ou mot de passe incorrect.');
    }
    await this.verrouillage.reussite(identifiantNormalise);

    // Compte non vérifié : renvoyer un token de vérification
    if (utilisateur.statutCompte === 'EN_ATTENTE_VERIFICATION') {
      // Activation = vérification du téléphone : toujours par SMS.
      const canal = 'SMS' as const;
      const destination = utilisateur.telephone!;

      const { code } = await this.otpService.generer({
        destination,
        canal,
        type: 'INSCRIPTION',
        utilisateurId: utilisateur.id,
      });

      await this.notificationService.envoyerOtp({
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

    await this.prisma.utilisateur
      .update({
        where: { id: utilisateur.id },
        data: {
          derniereConnexion: new Date(),
          // Re-hachage transparent si les paramètres argon2 ont changé
          ...(nouveauHash && { motDePasseHash: nouveauHash }),
        },
      })
      .catch(() => undefined);
    await this.journaliser(utilisateur.id, 'CONNEXION_REUSSIE', adresseIp);

    return this.jetonService.ouvrirSession({
      utilisateurId: utilisateur.id,
      statutCompte: utilisateur.statutCompte,
      telephoneVerifie: utilisateur.telephoneVerifieLe !== null,
      methodeAuth: estEmail ? 'EMAIL_MDP' : 'TELEPHONE_MDP',
      adresseIp,
    });
  }

  private journaliser(
    utilisateurId: string,
    evenement: 'CONNEXION_REUSSIE' | 'CONNEXION_ECHOUEE' | 'COMPTE_VERROUILLE',
    adresseIp?: string,
  ) {
    return this.prisma.journalSecurite
      .create({ data: { utilisateurId, evenement, adresseIp } })
      .catch(() => undefined);
  }
}
