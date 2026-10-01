import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type {
  ConfirmerChangementTelephoneDto,
  DemanderChangementTelephoneDto,
} from '../dto/changement-telephone.dto.js';
import { MotDePasseService } from '../services/mot-de-passe.service.js';
import { NotificationService } from '../services/notification.service.js';
import { OtpService } from '../services/otp.service.js';
import { TelephoneService } from '../services/telephone.service.js';

const TYPE_OTP = 'VERIFICATION_NOUVEAU_TELEPHONE' as const;

/**
 * Changement de numéro en deux étapes :
 * 1. mot de passe + nouveau numéro → OTP envoyé AU NOUVEAU numéro ;
 * 2. code reçu → numéro remplacé (tracé dans le journal de sécurité).
 */
@Injectable()
export class ChangementTelephoneService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otp: OtpService,
    private readonly telephone: TelephoneService,
    private readonly motDePasse: MotDePasseService,
    private readonly notification: NotificationService,
  ) {}

  async demander(utilisateurId: string, dto: DemanderChangementTelephoneDto) {
    const nouveau = this.telephone.normaliser(dto.nouveauTelephone);

    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: { telephone: true, motDePasseHash: true },
    });
    if (!utilisateur) throw new NotFoundException('Utilisateur introuvable.');

    if (utilisateur.motDePasseHash) {
      const { valide } = await this.motDePasse.verifier(
        dto.motDePasse ?? '',
        utilisateur.motDePasseHash,
      );
      if (!valide) throw new UnauthorizedException('Mot de passe incorrect.');
    }
    if (utilisateur.telephone === nouveau) {
      throw new BadRequestException('C’est déjà votre numéro.');
    }
    const pris = await this.prisma.utilisateur.count({
      where: { telephone: nouveau },
    });
    if (pris) throw new ConflictException('Ce numéro est déjà utilisé.');

    const { code, expiresAt } = await this.otp.generer({
      destination: nouveau,
      canal: 'SMS',
      type: TYPE_OTP,
      utilisateurId,
    });
    await this.notification.envoyerOtp({
      destination: nouveau,
      canal: 'SMS',
      code,
      type: 'verification',
    });

    return { telephone: nouveau, expireA: expiresAt };
  }

  async confirmer(
    utilisateurId: string,
    dto: ConfirmerChangementTelephoneDto,
    sessionCouranteIp?: string,
  ) {
    const nouveau = this.telephone.normaliser(dto.nouveauTelephone);

    const { utilisateurId: proprietaire } = await this.otp.verifier({
      destination: nouveau,
      type: TYPE_OTP,
      codeSoumis: dto.code,
    });
    if (proprietaire !== utilisateurId) {
      throw new ForbiddenException('Code invalide pour ce compte.');
    }

    const avant = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: { telephone: true },
    });

    try {
      await this.prisma.$transaction([
        this.prisma.utilisateur.update({
          where: { id: utilisateurId },
          data: { telephone: nouveau, telephoneVerifieLe: new Date() },
        }),
        this.prisma.journalSecurite.create({
          data: {
            utilisateurId,
            evenement: 'TELEPHONE_CHANGE',
            adresseIp: sessionCouranteIp,
            details: { ancien: masquer(avant?.telephone), nouveau: masquer(nouveau) },
          },
        }),
      ]);
    } catch (e) {
      if (
        typeof e === 'object' &&
        e !== null &&
        'code' in e &&
        (e as { code: string }).code === 'P2002'
      ) {
        throw new ConflictException('Ce numéro est déjà utilisé.');
      }
      throw e;
    }

    return { telephone: nouveau };
  }
}

/** +237650000001 → +2376*****001 (journal : pas de numéro complet). */
function masquer(numero?: string | null): string | null {
  if (!numero) return null;
  return numero.length > 7
    ? `${numero.slice(0, 5)}${'*'.repeat(numero.length - 8)}${numero.slice(-3)}`
    : '***';
}
