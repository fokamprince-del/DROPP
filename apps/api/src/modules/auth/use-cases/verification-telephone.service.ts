import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { OtpService } from '../services/otp.service.js';
import { JetonService, type JetonsEmis } from '../services/jeton.service.js';
import type { VerifierOtpDto } from '../dto/verifier-otp.dto.js';
import { VerificationEmailService } from './verification-email.service.js';

const STATUTS_AUTORISES = new Set(['EN_ATTENTE_VERIFICATION', 'ACTIF']);

@Injectable()
export class VerificationTelephoneService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    private readonly jetonService: JetonService,
    private readonly verificationEmail: VerificationEmailService,
  ) {}

  async executer(dto: VerifierOtpDto, adresseIp?: string): Promise<JetonsEmis> {
    // 1. Décoder le token de vérification
    const payload = this.jetonService.verifierTokenVerification(
      dto.verificationToken,
    );

    if (payload.purpose !== 'inscription') {
      throw new UnauthorizedException('Token de vérification invalide.');
    }
    // Ce code vérifie le TÉLÉPHONE : un code envoyé par email ne peut pas
    // le valider (anciens tokens émis avant le passage à l'activation SMS).
    if (payload.canalOtp !== 'SMS') {
      throw new UnauthorizedException(
        'Code expiré. Demandez un nouveau code par SMS.',
      );
    }

    // 2. Vérifier le compte
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        statutCompte: true,
        telephoneVerifieLe: true,
        email: true,
        emailVerifieLe: true,
      },
    });

    if (!utilisateur || !STATUTS_AUTORISES.has(utilisateur.statutCompte)) {
      // Consomme quand même l'OTP pour éviter les timing attacks
      await this.otpService
        .verifier({
          destination: payload.dst,
          type: 'INSCRIPTION',
          codeSoumis: dto.code,
        })
        .catch(() => undefined);
      throw new ForbiddenException('Compte indisponible.');
    }

    // 3. Vérifier l'OTP
    await this.otpService.verifier({
      destination: payload.dst,
      type: 'INSCRIPTION',
      codeSoumis: dto.code,
    });

    // 4. Passer le compte en ACTIF
    const maintenant = new Date();
    const mis_a_jour = await this.prisma.utilisateur.update({
      where: { id: utilisateur.id },
      data: {
        statutCompte: 'ACTIF',
        telephoneVerifieLe: utilisateur.telephoneVerifieLe ?? maintenant,
      },
      select: { statutCompte: true, telephoneVerifieLe: true },
    });

    // 5. Email fourni à l'inscription : envoi du code de confirmation
    //    (non bloquant — l'app propose ensuite l'écran « Confirmez votre email »).
    if (utilisateur.email && !utilisateur.emailVerifieLe) {
      void this.verificationEmail
        .envoyerCode(utilisateur.id)
        .catch(() => undefined);
    }

    // 6. Ouvrir la session
    return this.jetonService.ouvrirSession({
      utilisateurId: utilisateur.id,
      statutCompte: mis_a_jour.statutCompte,
      telephoneVerifie: mis_a_jour.telephoneVerifieLe !== null,
      methodeAuth: 'TELEPHONE_MDP',
      adresseIp,
    });
  }
}
