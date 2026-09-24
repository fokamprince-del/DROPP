import {
  ConflictException,
  Injectable,
  UnprocessableEntityException,
} from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/database/prisma.service.js';
import { OtpService } from '../services/otp.service.js';
import { MotDePasseService } from '../services/mot-de-passe.service.js';
import { TelephoneService } from '../services/telephone.service.js';
import { NotificationService } from '../services/notification.service.js';
import type { InscriptionDto } from '../dto/inscription.dto.js';

@Injectable()
export class InscriptionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly motDePasseService: MotDePasseService,
    private readonly otpService: OtpService,
    private readonly telephoneService: TelephoneService,
    private readonly notificationService: NotificationService,
  ) {}

  /**
   * Crée le compte + profil Client en une seule transaction.
   * Envoie ensuite l'OTP (hors transaction : un échec SMS ne doit pas
   * annuler la création du compte).
   */
  async executer(dto: InscriptionDto): Promise<{ utilisateurId: string }> {
    // 1. Normalisation
    const telephone = this.telephoneService.normaliser(dto.telephone);
    const email = dto.email ? dto.email.trim().toLowerCase() : null;

    // 2. Unicité — messages explicites à l'inscription uniquement
    //    (à la connexion et à la réinitialisation, réponse neutre)
    const existant = await this.prisma.utilisateur.findFirst({
      where: {
        OR: [{ telephone }, ...(email ? [{ email }] : [])],
      },
      select: { telephone: true, email: true },
    });

    if (existant) {
      if (existant.telephone === telephone) {
        throw new ConflictException('Ce numéro de téléphone est déjà utilisé.');
      }
      throw new ConflictException('Cette adresse email est déjà utilisée.');
    }

    // 3. Validation et hachage du mot de passe
    const motDePasseHash = await this.motDePasseService.hacher(dto.motDePasse);

    // 4. Création atomique : Utilisateur + Client dans la même transaction
    const utilisateur = await this.prisma.utilisateur.create({
      data: {
        prenom: dto.prenom.trim(),
        nom: dto.nom.trim(),
        telephone,
        email,
        motDePasseHash,
        // statutCompte reste EN_ATTENTE_VERIFICATION par défaut
        client: { create: {} },
      },
      select: { id: true },
    });

    // 5. Génération et envoi de l'OTP (hors transaction)
    const canal = email ? 'EMAIL' : 'SMS';
    const destination = canal === 'EMAIL' ? email! : telephone;

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

    return { utilisateurId: utilisateur.id };
  }
}
