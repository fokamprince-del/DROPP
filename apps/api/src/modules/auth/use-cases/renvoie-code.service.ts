import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { OtpService } from '../services/otp.service.js';
import { NotificationService } from '../services/notification.service.js';
import { JetonService } from '../services/jeton.service.js';
import type { RenvoiCodeDto } from '../dto/renvoi-code.dto.js';

@Injectable()
export class RenvoiCodeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    private readonly notificationService: NotificationService,
    private readonly jetonService: JetonService,
  ) {}

  async executer(dto: RenvoiCodeDto): Promise<{ verificationToken: string }> {
    // 1. Décoder le token de vérification
    const payload = this.jetonService.verifierTokenVerification(
      dto.verificationToken,
    );

    // 2. Vérifier que le compte existe encore
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: payload.sub },
      select: { id: true, statutCompte: true },
    });

    if (
      !utilisateur ||
      utilisateur.statutCompte === 'SUPPRIME' ||
      utilisateur.statutCompte === 'SUSPENDU_DEF'
    ) {
      throw new UnauthorizedException('Compte indisponible.');
    }

    // 3. Générer un nouveau code
    // OtpService gère le cooldown et le plafond horaire
    const { code } = await this.otpService.generer({
      destination: payload.dst,
      canal: payload.canalOtp,
      type: payload.purpose === 'inscription'
        ? 'INSCRIPTION'
        : 'REINITIALISATION_MOT_DE_PASSE',
      utilisateurId: utilisateur.id,
    });

    await this.notificationService.envoyerOtp({
      destination: payload.dst,
      canal: payload.canalOtp,
      code,
      type: payload.purpose === 'inscription' ? 'inscription' : 'reinitialisation',
    });

    // 4. Nouveau token de vérification (réinitialise le TTL de 15min)
    const verificationToken = this.jetonService.signerVerification({
      sub: utilisateur.id,
      dst: payload.dst,
      canalOtp: payload.canalOtp,
      purpose: payload.purpose,
    });

    return { verificationToken };
  }
}