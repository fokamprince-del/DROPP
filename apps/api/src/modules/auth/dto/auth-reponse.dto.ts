import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  MethodeAuthentification,
  PlateformeAppareil,
  StatutClient,
  StatutCompte,
  StatutVendeur,
} from '@dropp/database'; // imports de valeur : ce sont des enums Prisma

export class JetonsDto {
  @ApiProperty() accessToken!: string;
  @ApiProperty() refreshToken!: string;
  @ApiProperty({ type: 'integer', description: 'Durée de vie du jeton d’accès, en secondes.' })
  expiresIn!: number;
}

export class VerificationTokenDto {
  @ApiProperty({
    description:
      'À renvoyer avec le code reçu (/auth/verifier-telephone ou /auth/reinitialiser-mot-de-passe).',
  })
  verificationToken!: string;
}

/** Une seule forme de réponse, pour un client Dart simple : on teste `verificationRequise`. */
export class ConnexionReponseDto {
  @ApiProperty({ description: 'true : compte non vérifié, un code vient d’être envoyé.' })
  verificationRequise!: boolean;

  @ApiPropertyOptional({ description: 'Présents si verificationRequise = false.' })
  accessToken?: string;
  @ApiPropertyOptional() refreshToken?: string;
  @ApiPropertyOptional({ type: 'integer' }) expiresIn?: number;

  @ApiPropertyOptional({ description: 'Présent si verificationRequise = true.' })
  verificationToken?: string;

}

export class ProfilMeDto {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty() prenom!: string;
  @ApiProperty() nom!: string;
  @ApiProperty({ type: String, nullable: true }) email!: string | null;
  @ApiProperty() emailVerifie!: boolean;
  @ApiProperty({ type: String, nullable: true }) telephone!: string | null;
  @ApiProperty() telephoneVerifie!: boolean;
  @ApiProperty({ enum: StatutCompte, enumName: 'StatutCompte' }) statutCompte!: StatutCompte;
  @ApiProperty({ type: String, format: 'date-time' }) dateInscription!: Date;
  @ApiProperty({ type: String, format: 'date-time', nullable: true }) derniereConnexion!: Date | null;
  @ApiProperty() estClient!: boolean;
  @ApiProperty({ enum: StatutClient, enumName: 'StatutClient', nullable: true })
  statutClient!: StatutClient | null;
  @ApiProperty() estVendeur!: boolean;
  @ApiProperty({ enum: StatutVendeur, enumName: 'StatutVendeur', nullable: true })
  statutVendeur!: StatutVendeur | null;
}

export class AppareilSessionDto {
  @ApiProperty({ enum: PlateformeAppareil, enumName: 'PlateformeAppareil' })
  plateforme!: PlateformeAppareil;
  @ApiProperty({ type: String, nullable: true }) modele!: string | null;
}

export class SessionDto {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ enum: MethodeAuthentification, enumName: 'MethodeAuthentification' })
  methodeAuth!: MethodeAuthentification;
  @ApiProperty({ type: String, nullable: true }) adresseIpCreation!: string | null;
  @ApiProperty({ type: String, format: 'date-time' }) dateCreation!: Date;
  @ApiProperty({ type: String, format: 'date-time', nullable: true }) dateDerniereUtilisation!: Date | null;
  @ApiProperty({ type: String, format: 'date-time' }) dateExpiration!: Date;
  @ApiProperty({ type: AppareilSessionDto, nullable: true }) appareil!: AppareilSessionDto | null;
}


export class ChangeEmailDto {
    @ApiProperty() email: string;
    @ApiProperty({ type:'string', format: 'date-time' }) expireA: Date;
}

export class ChangeTelephoneDto {
    @ApiProperty() telephone: string; 
    @ApiProperty({ type:'string', format: 'date-time' }) expireA: Date
}