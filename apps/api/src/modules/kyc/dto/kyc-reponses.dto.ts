import { Prisma, StatutDocumentKyc, StatutKyc, StatutVendeur, StatutVerificationKyc, TypeDocumentKyc, TypeVerificationKyc } from "@dropp/database";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";


export class DemanderSignatureReponseDto {
    @ApiProperty({ enum: TypeDocumentKyc, }) 
    typeDocument: TypeDocumentKyc;

    @ApiProperty() uploadUrl: string;
    @ApiProperty() cleStockage: string;
    
    @ApiProperty({format:'date-time', type: String})
    expireA: Date;

    @ApiProperty({
    type: "object",
    additionalProperties: { type: "string" },
    example: {
      "Content-Type": "image/jpeg",
      "x-amz-meta-document": "cni",
    },
  })
  enTetes: Record<string, string>;
}



export class ConfirmerUploadKycReponseDto {
    @ApiProperty() id: string;

    @ApiProperty({ enum: TypeDocumentKyc}) 
    typeDocument: TypeDocumentKyc;
    
    @ApiProperty({enum: StatutDocumentKyc})
    statut: StatutDocumentKyc;

    @ApiProperty({ type: 'string', format: 'date-time'})
    dateCreation: Date;
}


class DonneesCniExtraitesDto {
  @ApiPropertyOptional()
  nomLegal?: string;

  @ApiPropertyOptional()
  prenomLegal?: string;

  @ApiPropertyOptional()
  numeroCni?: string;

  @ApiPropertyOptional({
    format: 'date',
    example: '2026-05-21',
  })
  dateNaissance?: string;

  @ApiPropertyOptional()
  lieuNaissance?: string;

  @ApiPropertyOptional({
    format: 'date',
    example: '2026-05-21',
  })
  dateEtablissement?: string;

  @ApiPropertyOptional({
    format: 'date',
    example: '2036-05-21',
  })
  dateExpiration?: string;

  @ApiProperty({
    minimum: 0,
    maximum: 100,
    description: 'Confiance de l’OCR en pourcentage.',
    example: 92,
  })
  confidence: number;
}

export class ExtractionCniReponseDto {
  @ApiProperty({ type: DonneesCniExtraitesDto })
  donnees: DonneesCniExtraitesDto;

  @ApiProperty({
    type: String,
    nullable: true,
    example: 'Certaines informations sont difficiles à lire.',
  })
  avertissement: string | null;
}



export class ConfirmationOCRResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ nullable: true })
  nomLegal: string | null;

  @ApiProperty({ nullable: true })
  prenomLegal: string | null;

  @ApiProperty({ nullable: true })
  numeroCni: string | null;

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
  })
  dateNaissance: Date | null;

  @ApiProperty({ nullable: true })
  lieuNaissance: string | null;

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
  })
  dateEtablissement: Date | null;

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
  })
  dateExpiration: Date | null;
}

export class MessageReponseDto {
  @ApiProperty({ description: 'statut du dossier'}) 
  statut: string;

  @ApiProperty() message: string;
}

class DocumentKycDto {
  @ApiProperty({ enum: StatutDocumentKyc })
  statut: StatutDocumentKyc;

  @ApiProperty()
  id: string;

  @ApiProperty({ enum: TypeDocumentKyc })
  typeDocument: TypeDocumentKyc;

  @ApiProperty({ type: String, format: 'date-time' })
  dateCreation: Date;
}

export class ConsulterDossierKycVendeurResponseDto {
  @ApiProperty({ enum: StatutKyc })
  statut: StatutKyc;

  @ApiProperty()
  id: string;

  @ApiProperty({ type: String, format: 'date-time' })
  dateSoumission: Date;

  @ApiProperty({ nullable: true })
  nomLegal: string | null;

  @ApiProperty({ nullable: true })
  prenomLegal: string | null;

  @ApiProperty({ nullable: true })
  numeroCni: string | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  dateNaissance: Date | null;

  @ApiProperty({ nullable: true })
  lieuNaissance: string | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  dateEtablissement: Date | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  dateExpiration: Date | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  dateValidation: Date | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  dateRejet: Date | null;

  @ApiProperty({ nullable: true })
  motifRejet: string | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  consentementLe: Date | null;

  @ApiProperty({ type: [DocumentKycDto] })
  documents: DocumentKycDto[];
}


class BoutiqueKycResumeDto {
  @ApiProperty()
  nom: string;
}

class UtilisateurKycResumeDto {
  @ApiProperty()
  prenom: string;

  @ApiProperty()
  nom: string;

  @ApiProperty({ nullable: true })
  telephone: string | null;
}

class VendeurKycResumeDto {
  @ApiProperty({ type: () => BoutiqueKycResumeDto, nullable: true })
  boutique: BoutiqueKycResumeDto | null;

  @ApiProperty({ type: () => UtilisateurKycResumeDto })
  utilisateur: UtilisateurKycResumeDto;
}

class DossierKycResumeDto {
  @ApiProperty({ enum: StatutKyc })
  statut: StatutKyc;

  @ApiProperty()
  id: string;

  @ApiProperty({ type: String, format: 'date-time' })
  dateSoumission: Date;

  @ApiProperty({ type: String, nullable: true })
  scoreFaceMatch: any | null;

  @ApiProperty({ type: () => VendeurKycResumeDto })
  vendeur: VendeurKycResumeDto;
}


export class PaginationReponseDto {
  @ApiProperty()
  total: number;

  @ApiProperty()
  page: number;

  @ApiProperty()
  limite: number;

  @ApiProperty()
  pages: number;
}

export class ListeDossiersKycReponseDto {
  @ApiProperty({ type: [DossierKycResumeDto] })
  donnees: DossierKycResumeDto[];

  @ApiProperty({ type: PaginationReponseDto })
  pagination: PaginationReponseDto;
}

class UtilisateurDetailKycDto {
  @ApiProperty()
  prenom: string;

  @ApiProperty()
  nom: string;

  @ApiProperty()
  telephone: string;

  @ApiProperty({ nullable: true})
  email: string  | null;
}

class BoutiqueDetailKycDto {
  @ApiProperty()
  nom: string;

  @ApiProperty({ nullable: true })
  ville: string | null;

  @ApiProperty({ nullable: true })
  quartier: string | null;
}

class VendeurDetailKycDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ enum: StatutVendeur })
  statutVendeur: StatutVendeur;

  @ApiProperty({ type: () => UtilisateurDetailKycDto })
  utilisateur: UtilisateurDetailKycDto;

  @ApiProperty({ type: () => BoutiqueDetailKycDto, nullable: true })
  boutique: BoutiqueDetailKycDto | null;
}

class DocumentDetailKycDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ enum: TypeDocumentKyc })
  typeDocument: TypeDocumentKyc;

  @ApiProperty({ enum: StatutDocumentKyc })
  statut: StatutDocumentKyc;

  @ApiProperty({ type: String, format: 'uri' })
  urlConsultation: string;
}

class VerificationKycDto {
  @ApiProperty({ enum: TypeVerificationKyc })
  typeVerification: TypeVerificationKyc;

  @ApiProperty({ enum: StatutVerificationKyc })
  statut: StatutVerificationKyc;

  @ApiProperty({ type: String, nullable: true })
  scoreMatching: any | null;

  @ApiProperty({ nullable: true })
  commentaire: string | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  dateVerification: Date | null;
}

class AdministrateurRevueKycDto {
  @ApiProperty()
  prenom: string;

  @ApiProperty()
  nom: string;
}

class RevueKycDto {
  @ApiProperty({ enum: StatutKyc })
  statut: StatutKyc;

  @ApiProperty({ nullable: true })
  commentaire: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  dateRevue: Date;

  @ApiProperty({ type: () => AdministrateurRevueKycDto })
  administrateur: AdministrateurRevueKycDto;
}

export class ConsulterDossierKycAdminReponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ enum: StatutKyc })
  statut: StatutKyc;

  @ApiProperty({ nullable: true })
  nomLegal: string | null;

  @ApiProperty({ nullable: true })
  prenomLegal: string | null;

  @ApiProperty({ nullable: true })
  numeroCni: string | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  dateNaissance: Date | null;

  @ApiProperty({ nullable: true })
  lieuNaissance: string | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  dateEtablissement: Date | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  dateExpiration: Date | null;

  @ApiProperty({ type: String, nullable: true })
  scoreFaceMatch: any | null;

  @ApiProperty({ nullable: true })
  motifRejet: string | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  consentementLe: Date | null;

  @ApiProperty({ type: String, format: 'date-time' })
  dateSoumission: Date;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  dateValidation: Date | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  dateRejet: Date | null;

  @ApiProperty({ type: () => VendeurDetailKycDto })
  vendeur: VendeurDetailKycDto;

  @ApiProperty({ type: () => [DocumentDetailKycDto] })
  documents: DocumentDetailKycDto[];

  @ApiProperty({ type: () => [VerificationKycDto] })
  verifications: VerificationKycDto[];

  @ApiProperty({ type: () => [RevueKycDto] })
  revues: RevueKycDto[];
}




