import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';

import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import type { ChangerMotDePasseDto } from '../dto/email.dto.js';
import { JetonService, type JetonsEmis } from '../services/jeton.service.js';
import { MotDePasseService } from '../services/mot-de-passe.service.js';

/**
 * Changement de mot de passe depuis l'app (utilisateur connecté).
 * Toutes les sessions sont révoquées (un voleur de session est déconnecté),
 * puis une nouvelle session est ouverte pour l'appareil courant.
 */
@Injectable()
export class ChangementMotDePasseService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly motDePasse: MotDePasseService,
    private readonly jetons: JetonService,
  ) {}

  async executer(
    utilisateurId: string,
    dto: ChangerMotDePasseDto,
    adresseIp?: string,
  ): Promise<JetonsEmis> {
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: utilisateurId },
      select: {
        motDePasseHash: true,
        statutCompte: true,
        telephoneVerifieLe: true,
      },
    });
    if (!utilisateur) throw new NotFoundException('Utilisateur introuvable.');
    if (!utilisateur.motDePasseHash) {
      throw new BadRequestException(
        'Ce compte n’a pas de mot de passe : utilisez « Mot de passe oublié ».',
      );
    }

    const { valide } = await this.motDePasse.verifier(
      dto.ancienMotDePasse,
      utilisateur.motDePasseHash,
    );
    if (!valide) throw new UnauthorizedException('Mot de passe actuel incorrect.');
    if (dto.ancienMotDePasse === dto.nouveauMotDePasse) {
      throw new BadRequestException(
        'Le nouveau mot de passe doit être différent de l’actuel.',
      );
    }

    // hacher() valide aussi la robustesse (longueur, zxcvbn).
    const nouveauHash = await this.motDePasse.hacher(dto.nouveauMotDePasse);

    await this.prisma.$transaction([
      this.prisma.utilisateur.update({
        where: { id: utilisateurId },
        data: { motDePasseHash: nouveauHash },
      }),
      this.prisma.session.updateMany({
        where: { utilisateurId, dateRevocation: null },
        data: { dateRevocation: new Date() },
      }),
      this.prisma.journalSecurite.create({
        data: { utilisateurId, evenement: 'MOT_DE_PASSE_CHANGE', adresseIp },
      }),
    ]);

    return this.jetons.ouvrirSession({
      utilisateurId,
      statutCompte: utilisateur.statutCompte,
      telephoneVerifie: utilisateur.telephoneVerifieLe !== null,
      methodeAuth: 'TELEPHONE_MDP',
      adresseIp,
    });
  }
}
