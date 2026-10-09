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
  demanderSignatureDocument(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: DemanderSignatureDocumentKycDto,
  ) {
    return this.uploadDocument.demanderSignature(u.id, dto);
  }

  @Vendeur('EN_ATTENTE_VALIDATION')
  @Post('kyc/documents/confirmer')
  @HttpCode(HttpStatus.CREATED)
  confirmerDocument(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: ConfirmerUploadDocumentKycDto,
  ) {
    return this.uploadDocument.confirmerUpload(u.id, dto);
  }

  // ── OCR ───────────────────────────────────────────────────────────────────

  /** Pré-remplissage depuis la CNI recto : coûteux, donc fortement limité. */
  @Throttle({ court: { limit: 3, ttl: 60_000 } })
  @Vendeur('EN_ATTENTE_VALIDATION')
  @Post('kyc/cni/extraire')
  @HttpCode(HttpStatus.OK)
  extraireCni(@CurrentUser() u: UtilisateurConnecte) {
    return this.extraireDonneesCni.executer(u.id);
  }

  @Vendeur('EN_ATTENTE_VALIDATION')
  @Post('kyc/cni/confirmer')
  @HttpCode(HttpStatus.OK)
  confirmerCni(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: DonneesCniDto,
  ) {
    return this.confirmerDonneesCni.executer(u.id, dto);
  }

  // ── Soumission ────────────────────────────────────────────────────────────

  /** Body : { consentement: true } (traitement des pièces, vérification faciale). */
  @Vendeur('EN_ATTENTE_VALIDATION')
  @RequiertIdempotenceKey()
  @Post('kyc/soumettre')
  @HttpCode(HttpStatus.OK)
  soumettre(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() _dto: SoumettreDossierKycDto,
  ) {
    return this.soumettreDossier.executer(u.id);
  }

  // ── Consultation vendeur ──────────────────────────────────────────────────

  @Vendeur('EN_ATTENTE_VALIDATION', 'ACTIF', 'SUSPENDU')
  @Get('kyc/mon-dossier')
  monDossier(@CurrentUser() u: UtilisateurConnecte) {
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
  ) {
    return this.consulterDossier.listerPourAdmin({
      statut,
      page: Math.max(page, 1),
      limite: Math.min(Math.max(limite, 1), 50),
    });
  }

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Get('admin/kyc/:id')
  consulterDossierAdmin(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.consulterDossier.pourAdmin(id, u.id);
  }

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Post('admin/kyc/:id/decision')
  @HttpCode(HttpStatus.OK)
  prendreDecision(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: DecisionAdminDto,
  ) {
    return this.decisionAdmin.executer(id, u.id, dto);
  }
}
