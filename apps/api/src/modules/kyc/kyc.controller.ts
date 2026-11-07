import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseEnumPipe,
  ParseIntPipe,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';

import { StatutKyc } from '@dropp/database';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { Admin, Vendeur } from '../auth/decorators/profils.decorator.js';
import { RequiertIdempotenceKey } from '../../infrastructure/idempotence/idempotence.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';

import { ConfirmerUploadDocumentKycDto } from './dto/confirmer-upload-document-kyc.dto.js';
import { DecisionAdminDto } from './dto/decision-admin.dto.js';
import { DemanderSignatureDocumentKycDto } from './dto/DemanderSignatureDocumentKyc.dto.js';
import { DonneesCniDto } from './dto/donnees-cni.dto.js';
import { SoumettreDossierKycDto } from './dto/soumettre-dossier.dto.js';

import { ConfirmerDonneesCniService } from './use-cases/confirmer-donnees-cni.service.js';
import { ConsulterDossierService } from './use-cases/consulter-dossier.service.js';
import { DecisionAdminService } from './use-cases/decision-admin.service.js';
import { ExtraireDonneesCniService } from './use-cases/extraire-donnees-cni.service.js';
import { SoumettreDoissierService } from './use-cases/soummetre-dossier-kyc.service.js';
import { UploadDocumentService } from './use-cases/upload-document.service.js';
import { ApiCreatedResponse, ApiOkResponse } from '@nestjs/swagger';
import { ConfirmationOCRResponseDto, ConfirmerUploadKycReponseDto, ConsulterDossierKycAdminReponseDto, ConsulterDossierKycVendeurResponseDto, DemanderSignatureReponseDto, ExtractionCniReponseDto, ListeDossiersKycReponseDto, MessageReponseDto } from './dto/kyc-reponses.dto.js';
import { ApiErreurs } from '../../infrastructure/http/api-erreur.decorator.js';

/**
 * Parcours KYC : réservé aux vendeurs EN ATTENTE de validation
 * (un vendeur devient ACTIF une fois son dossier validé).
 * Ordre côté app : documents (signature → PUT → confirmer) ×3,
 * OCR (facultatif), confirmation des données CNI, soumission.
 */
@Controller()
export class KycController {
  constructor(
    private readonly uploadDocument: UploadDocumentService,
    private readonly extraireDonneesCni: ExtraireDonneesCniService,
    private readonly confirmerDonneesCni: ConfirmerDonneesCniService,
    private readonly soumettreDossier: SoumettreDoissierService,
    private readonly consulterDossier: ConsulterDossierService,
    private readonly decisionAdmin: DecisionAdminService,
  ) {}

  // ── Documents KYC ─────────────────────────────────────────────────────────

  @Throttle({ court: { limit: 10, ttl: 60_000 } })
  @Vendeur('EN_ATTENTE_VALIDATION')
  @Post('kyc/documents/signature')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({type: DemanderSignatureReponseDto, })
  demanderSignatureDocument(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: DemanderSignatureDocumentKycDto,
  ): Promise<DemanderSignatureReponseDto> {
    return this.uploadDocument.demanderSignature(u.id, dto);
  }

  @Vendeur('EN_ATTENTE_VALIDATION')
  @Post('kyc/documents/confirmer')
  @HttpCode(HttpStatus.CREATED)
  @ApiCreatedResponse({type: ConfirmerUploadKycReponseDto})
  confirmerDocument(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: ConfirmerUploadDocumentKycDto,
  ): Promise<ConfirmerUploadKycReponseDto> {
    return this.uploadDocument.confirmerUpload(u.id, dto);
  }

  // ── OCR ───────────────────────────────────────────────────────────────────

  /** Pré-remplissage depuis la CNI recto : coûteux, donc fortement limité. */
  @Throttle({ court: { limit: 3, ttl: 60_000 } })
  @Vendeur('EN_ATTENTE_VALIDATION')
  @Post('kyc/cni/extraire')
  @HttpCode(HttpStatus.OK)
  @ApiErreurs(404)
  @ApiOkResponse({type: ExtractionCniReponseDto})
  extraireCni(
    @CurrentUser() u: UtilisateurConnecte
  ): Promise<ExtractionCniReponseDto> {
    return this.extraireDonneesCni.executer(u.id);
  }

  @Vendeur('EN_ATTENTE_VALIDATION')
  @Post('kyc/cni/confirmer')
  @HttpCode(HttpStatus.OK)
  @ApiErreurs(400)
  @ApiOkResponse({type: ConfirmationOCRResponseDto})
  confirmerCni(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: DonneesCniDto,
  ): Promise<ConfirmationOCRResponseDto> {
    return this.confirmerDonneesCni.executer(u.id, dto);
  }

  // ── Soumission ────────────────────────────────────────────────────────────

  /** Body : { consentement: true } (traitement des pièces, vérification faciale). */
  @Vendeur('EN_ATTENTE_VALIDATION')
  @RequiertIdempotenceKey()
  @Post('kyc/soumettre')
  @HttpCode(HttpStatus.OK)
  @ApiErreurs(400, 409)
  @ApiOkResponse({
    type: MessageReponseDto, 
    example: {
      statut: 'EN_COURS_VERIFICATION',
      message: 'Dossier soumis. La vérification est en cours.',
    }
  })
  soumettre(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() _dto: SoumettreDossierKycDto,
  ): Promise<MessageReponseDto> {
    return this.soumettreDossier.executer(u.id);
  }

  // ── Consultation vendeur ──────────────────────────────────────────────────

  @Vendeur('EN_ATTENTE_VALIDATION', 'ACTIF', 'SUSPENDU')
  @Get('kyc/mon-dossier')
  monDossier(
    @CurrentUser() u: UtilisateurConnecte
  ): Promise<ConsulterDossierKycVendeurResponseDto> {
    return this.consulterDossier.pourVendeur(u.id);
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Get('admin/kyc')
  listerDossiers(
    @Query('statut', new ParseEnumPipe(StatutKyc, { optional: true }))
    statut?: StatutKyc,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ): Promise<ListeDossiersKycReponseDto> {
    return this.consulterDossier.listerPourAdmin({
      statut,
      page: Math.max(page, 1),
      limite: Math.min(Math.max(limite, 1), 50),
    });
  }

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Get('admin/kyc/:id')
  @ApiErreurs(404)
  consulterDossierAdmin(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ConsulterDossierKycAdminReponseDto> {
    return this.consulterDossier.pourAdmin(id, u.id);
  }

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Post('admin/kyc/:id/decision')
  @HttpCode(HttpStatus.OK)
  @ApiErreurs(404,400,409)
  prendreDecision(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: DecisionAdminDto,
  ): Promise<MessageReponseDto> {
    return this.decisionAdmin.executer(id, u.id, dto);
  }
}
