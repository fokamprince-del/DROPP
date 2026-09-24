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
    const estEmail = dto.destination.includes('@');
    const destination = estEmail
      ? dto.destination.trim().toLowerCase()
      : dto.destination.trim();

    const utilisateur = await this.prisma.utilisateur.findFirst({
      where: estEmail ? { email: destination } : { telephone: destination },
      select: {
        id: true,
        statutCompte: true,
        telephoneVerifieLe: true,
      },
    });

    if (!utilisateur) {
      // Anti-énumération : on vérifie quand même l'OTP
      await this.otpService
        .verifier({
          destination,
          type: 'REINITIALISATION_MOT_DE_PASSE',
          codeSoumis: dto.code,
        })
        .catch(() => undefined);
      throw new BadRequestException('Code invalide ou expiré.');
    }

    // Vérification OTP — lève BadRequestException / GoneException si invalide
    await this.otpService.verifier({
      destination,
      type: 'REINITIALISATION_MOT_DE_PASSE',
      codeSoumis: dto.code,
    });

    const nouveauHash = await this.motDePasseService.hacher(
      dto.nouveauMotDePasse,
    );

    // Changement MDP + révocation de toutes les sessions dans la même transaction
    await this.prisma.$transaction([
      this.prisma.utilisateur.update({
        where: { id: utilisateur.id },
        data: { motDePasseHash: nouveauHash },
      }),
      this.prisma.session.updateMany({
        where: { utilisateurId: utilisateur.id, dateRevocation: null },
        data: { dateRevocation: new Date() },
      }),
    ]);

    // Nouvelle session propre
    return this.jetonService.ouvrirSession({
      utilisateurId: utilisateur.id,
      statutCompte: utilisateur.statutCompte,
      telephoneVerifie: utilisateur.telephoneVerifieLe !== null,
      methodeAuth: estEmail ? 'EMAIL_MDP' : 'TELEPHONE_MDP',
      adresseIp,
    });
  }
}
