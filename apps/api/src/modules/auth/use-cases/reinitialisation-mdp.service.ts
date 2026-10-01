import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { OtpService } from '../services/otp.service.js';
import { MotDePasseService } from '../services/mot-de-passe.service.js';
import { JetonService, type JetonsEmis } from '../services/jeton.service.js';
import type { ReinitialisationMdpDto } from '../dto/reinitialisation-mdp.dto.js';

@Injectable()
export class ReinitialisationMdpService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    private readonly motDePasseService: MotDePasseService,
    private readonly jetonService: JetonService,
  ) {}

  /**
   * Vérifie l'OTP, change le mot de passe et révoque toutes les sessions.
   * Ouvre une nouvelle session propre après réinitialisation.
   */
  async executer(
    dto: ReinitialisationMdpDto,
    adresseIp?: string,
  ): Promise<JetonsEmis> {
    // 1. Décoder le token de vérification
    const payload = this.jetonService.verifierTokenVerification(
      dto.verificationToken,
    );

    if (payload.purpose !== 'reinitialisation') {
      throw new BadRequestException('Token invalide.');
    }

    // 2. Vérifier le compte
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: payload.sub },
      select: { id: true, statutCompte: true, telephoneVerifieLe: true },
    });

    if (
      !utilisateur ||
      utilisateur.statutCompte === 'SUPPRIME' ||
      utilisateur.statutCompte === 'SUSPENDU_DEF'
    ) {
      await this.otpService
        .verifier({
          destination: payload.dst,
          type: 'REINITIALISATION_MOT_DE_PASSE',
          codeSoumis: dto.code,
        })
        .catch(() => undefined);
      throw new BadRequestException('Code invalide ou expiré.');
    }

    // 3. Vérifier l'OTP
    await this.otpService.verifier({
      destination: payload.dst,
      type: 'REINITIALISATION_MOT_DE_PASSE',
      codeSoumis: dto.code,
    });

    // 4. Changer le MDP + révoquer toutes les sessions
    const nouveauHash = await this.motDePasseService.hacher(
      dto.nouveauMotDePasse,
    );

    // Code reçu par SMS = possession du téléphone prouvée : un compte encore
    // en attente de vérification est activé au passage.
    const viaSms = payload.canalOtp === 'SMS';
    const activer =
      viaSms && utilisateur.statutCompte === 'EN_ATTENTE_VERIFICATION';
    const telephoneVerifieLe =
      utilisateur.telephoneVerifieLe ?? (viaSms ? new Date() : null);
    const statutCompte = activer ? 'ACTIF' : utilisateur.statutCompte;

    await this.prisma.$transaction([
      this.prisma.utilisateur.update({
        where: { id: utilisateur.id },
        data: { motDePasseHash: nouveauHash, telephoneVerifieLe, statutCompte },
      }),
      this.prisma.session.updateMany({
        where: { utilisateurId: utilisateur.id, dateRevocation: null },
        data: { dateRevocation: new Date() },
      }),
      this.prisma.journalSecurite.create({
        data: {
          utilisateurId: utilisateur.id,
          evenement: 'REINITIALISATION_MDP_EFFECTUEE',
          adresseIp,
        },
      }),
    ]);

    // 5. Nouvelle session propre
    return this.jetonService.ouvrirSession({
      utilisateurId: utilisateur.id,
      statutCompte,
      telephoneVerifie: telephoneVerifieLe !== null,
      methodeAuth: payload.dst.includes('@') ? 'EMAIL_MDP' : 'TELEPHONE_MDP',
      adresseIp,
    });
  }
}
