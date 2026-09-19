import {
  ConflictException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

import { PrismaService } from '../../infrastructure/database/prisma.service.js';

import {
  SMS_PROVIDER,
} from '../../infrastructure/sms/sms-provider.js';
import type { SmsProvider } from '../../infrastructure/sms/sms-provider.js';

import { ConnexionDto } from './dto/connexion.dto.js';
import { InscriptionDto } from './dto/inscription.dto.js';
import { RenvoiCodeDto } from './dto/renvoi-code.dto.js';
import { VerificationOtpDto } from './dto/verification-otp.dto.js';
import { RenouvellementTokenDto } from './dto/renouvellement-token.dto.js';

import { MotDePasseService } from './services/mot-de-passe.service.js';
import { OtpService } from './services/otp.service.js';
import { SessionService } from './services/session.service.js';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthentificationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly motDePasseService: MotDePasseService,
    private readonly otpService: OtpService,
    private readonly sessionService: SessionService,
    private readonly configService: ConfigService,

    @Inject(SMS_PROVIDER)
    private readonly smsProvider: SmsProvider,
  ) {}

  async inscrire(
    dto: InscriptionDto,
    adresseIp?: string,
  ) {
    const email = dto.email
      .trim()
      .toLowerCase();

    const telephone =
      dto.telephone.replace(
        /[\s().-]/g,
        '',
      );

    const motDePasseHash =
      await this.motDePasseService.hacher(
        dto.motDePasse,
      );

    const code =
      this.otpService.generer();

    /*
     * TODO futur :
     * Remplacer le hash OTP provisoire par
     * HMAC/secret serveur + Outbox.
     *
     * Ne jamais mettre le code en clair
     * dans une future table Outbox.
     */

    const codeHash =
      await this.motDePasseService.hacher(
        code,
      );

    try {
      const resultat =
        await this.prisma.$transaction(
          async (tx) => {
            const utilisateur =
              await tx.utilisateur.create({
                data: {
                  nom: dto.nom.trim(),
                  prenom: dto.prenom.trim(),
                  email,
                  telephone,
                  motDePasseHash,
                  statutCompte:
                    'EN_ATTENTE_VERIFICATION',
                },
              });

            await tx.client.create({
              data: {
                id: utilisateur.id,
              },
            });

            await tx.codeVerification.create({
              data: {
                utilisateurId:
                  utilisateur.id,

                destination:
                  telephone,

                codeHash,

                type:
                  'INSCRIPTION',

                dateExpiration:
                  new Date(
                    Date.now() +
                      10 * 60 * 1000,
                  ),
              },
            });

            return utilisateur;
          },
        );

      /*
       * Pour l'instant nous retournons le code
       * uniquement en développement.
       *
       * En production, cette partie sera remplacée
       * par Outbox -> Worker -> SmsProvider.
       */
      this.smsProvider.envoyerCodeVerification(
        telephone,
        code,
      );

      return {
        utilisateurId: resultat.id,
        email: resultat.email,
        telephone: resultat.telephone,
        verificationRequise: true,
      };
    } catch (error: any) {
      if (
        error?.code === 'P2002'
      ) {
        throw new ConflictException(
          'Un compte utilise déjà cet email ou ce numéro de téléphone.',
        );
      }

      throw error;
    }
  }

  async verifierInscription(
    utilisateurId: string,
    dto: VerificationOtpDto,
  ) {
    const utilisateur =
      await this.prisma.utilisateur.findUnique({
        where: {
          id: utilisateurId,
        },
      });

    if (!utilisateur) {
      throw new UnauthorizedException(
        'Code de vérification invalide.',
      );
    }

    if (
      utilisateur.statutCompte ===
      'ACTIF'
    ) {
      return {
        message:
          'Le compte est déjà vérifié.',
      };
    }

    const code =
      await this.prisma.codeVerification.findFirst({
        where: {
          utilisateurId,
          type: 'INSCRIPTION',
          dateUtilisation: null,
          dateExpiration: {
            gt: new Date(),
          },
        },
        orderBy: {
          dateCreation: 'desc',
        },
      });

    if (!code) {
      throw new UnauthorizedException(
        'Code de vérification invalide ou expiré.',
      );
    }

    if (
      code.nombreTentatives >= 5
    ) {
      throw new UnauthorizedException(
        'Nombre maximal de tentatives atteint.',
      );
    }

    const valide =
      await this.motDePasseService.verifier(
        code.codeHash,
        dto.code,
      );

    if (!valide) {
      await this.prisma.codeVerification.update({
        where: {
          id: code.id,
        },
        data: {
          nombreTentatives: {
            increment: 1,
          },
        },
      });

      throw new UnauthorizedException(
        'Code de vérification invalide.',
      );
    }

    await this.prisma.$transaction([
      this.prisma.codeVerification.update({
        where: {
          id: code.id,
        },
        data: {
          dateUtilisation: new Date(),
        },
      }),

      this.prisma.utilisateur.update({
        where: {
          id: utilisateurId,
        },
        data: {
          statutCompte: 'ACTIF',
        },
      }),
    ]);

    return {
      message:
        'Compte vérifié avec succès.',
    };
  }

  async renvoyerCode(
    dto: RenvoiCodeDto,
  ) {
    const email = dto.email
      .trim()
      .toLowerCase();

    const utilisateur =
      await this.prisma.utilisateur.findUnique({
        where: {
          email,
        },
      });

    /*
     * Nous ne révélons pas l'existence du compte.
     */
    if (
      !utilisateur ||
      utilisateur.statutCompte ===
        'ACTIF'
    ) {
      return {
        message:
          'Si un compte correspondant existe, un nouveau code sera envoyé.',
      };
    }

    const code =
      this.otpService.generer();

    const codeHash =
      await this.motDePasseService.hacher(
        code,
      );

    await this.prisma.codeVerification.updateMany({
      where: {
        utilisateurId:
          utilisateur.id,

        type: 'INSCRIPTION',

        dateUtilisation: null,
      },

      data: {
        dateUtilisation:
          new Date(),
      },
    });

    await this.prisma.codeVerification.create({
      data: {
        utilisateurId:
          utilisateur.id,

        destination:
          utilisateur.telephone,

        codeHash,

        type:
          'INSCRIPTION',

        dateExpiration:
          new Date(
            Date.now() +
              10 * 60 * 1000,
          ),
      },
    });

    this.smsProvider.envoyerCodeVerification(
      utilisateur.telephone,
      code,
    );

    return {
      message:
        'Si un compte correspondant existe, un nouveau code sera envoyé.',
    };
  }

  async connecter(
    dto: ConnexionDto,
    adresseIp?: string,
  ) {
    const telephone = dto.telephone
      .trim()
      .toLowerCase();

    const utilisateur =
      await this.prisma.utilisateur.findUnique({
        where: {
          telephone,
        },
      });

    /*
     * Ne jamais distinguer :
     * - telephone inexistant
     * - mauvais mot de passe
     */
    if (!utilisateur) {
      throw new UnauthorizedException(
        'Telephone ou mot de passe incorrect.',
      );
    }

    const motDePasseValide =
      await this.motDePasseService.verifier(
        utilisateur.motDePasseHash,
        dto.motDePasse,
      );

    if (!motDePasseValide) {
      throw new UnauthorizedException(
        'Email ou mot de passe incorrect.',
      );
    }

    if (
      utilisateur.statutCompte !==
      'ACTIF'
    ) {
      throw new UnauthorizedException(
        'Ce compte n’est pas disponible.',
      );
    }

    await this.prisma.utilisateur.update({
      where: {
        id: utilisateur.id,
      },

      data: {
        derniereConnexion:
          new Date(),
      },
    });

    return this.sessionService.creerSession({
      utilisateurId:
        utilisateur.id,

      adresseIp,
    });
  }

  async renouveler(
    dto: RenouvellementTokenDto,
  ) {
    return this.sessionService.renouvelerSession(
      dto.jetonRafraichissement,
    );
  }

  async deconnecter(
    sessionId: string,
  ): Promise<void> {
    await this.sessionService.revoquerSession(
      sessionId,
    );
  }

  async deconnecterPartout(
    utilisateurId: string,
  ): Promise<void> {
    await this.sessionService.revoquerToutesLesSessions(
      utilisateurId,
    );
  }
}