import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { OtpService } from '../services/otp.service.js';
import { JetonService, type JetonsEmis } from '../services/jeton.service.js';
import type { VerifierOtpDto } from '../dto/verifier-otp.dto.js';

const STATUTS_AUTORISES = new Set(['EN_ATTENTE_VERIFICATION', 'ACTIF']);

@Injectable()
export class VerificationTelephoneService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    private readonly jetonService: JetonService,
  ) {}

  /**
   * Vérifie le code OTP, passe le compte en ACTIF, ouvre la première session.
   * Réponse neutre si l'identifiant est inconnu (anti-énumération).
   */
  async executer(
    dto: VerifierOtpDto,
    adresseIp?: string,
  ): Promise<JetonsEmis> {
    // La destination est le téléphone (normalisé) ou l'email selon ce qui
    // a été utilisé à l'inscription.
    const utilisateur = await this.prisma.utilisateur.findFirst({
      where: {
        OR: [{ telephone: dto.destination }, { email: dto.destination }],
      },
      select: {
        id: true,
        statutCompte: true,
        telephoneVerifieLe: true,
      },
    });

    // Réponse identique si l'utilisateur n'existe pas : pas de fuite
    if (!utilisateur || !STATUTS_AUTORISES.has(utilisateur.statutCompte)) {
      // On vérifie quand même le code pour consommer une tentative
      // et ne pas révéler l'inexistence du compte par un temps de réponse différent.
      await this.otpService
        .verifier({ destination: dto.destination, type: 'INSCRIPTION', codeSoumis: dto.code })
        .catch(() => undefined);
      throw new NotFoundException('Code invalide ou expiré.');
    }

    // Lance BadRequestException / GoneException si le code est mauvais
    await this.otpService.verifier({
      destination: dto.destination,
      type: 'INSCRIPTION',
      codeSoumis: dto.code,
    });

    const maintenant = new Date();

    // Passage en ACTIF + enregistrement de la date de vérification
    const mis_a_jour = await this.prisma.utilisateur.update({
      where: { id: utilisateur.id },
      data: {
        statutCompte: 'ACTIF',
        telephoneVerifieLe: utilisateur.telephoneVerifieLe ?? maintenant,
      },
      select: { statutCompte: true, telephoneVerifieLe: true },
    });

    // Ouvre la première session après vérification
    return this.jetonService.ouvrirSession({
      utilisateurId: utilisateur.id,
      statutCompte: mis_a_jour.statutCompte,
      telephoneVerifie: mis_a_jour.telephoneVerifieLe !== null,
      methodeAuth: 'TELEPHONE_MDP',
      adresseIp,
    });
  }
}