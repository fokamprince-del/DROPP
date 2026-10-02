import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Ip,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';

import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { Vendeur } from '../auth/decorators/profils.decorator.js';
import { Admin } from '../auth/decorators/profils.decorator.js';
import { RequiertIdempotenceKey } from '../../infrastructure/idempotence/idempotence.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';

import { DonneesCniDto } from './dto/donnees-cni.dto.js';
import { DecisionAdminDto } from './dto/decision-admin.dto.js';

import { UploadDocumentService } from './use-cases/upload-document.service.js';
import { ExtraireDonneesCniService } from './use-cases/extraire-donnees-cni.service.js';
import { ConfirmerDonneesCniService } from './use-cases/confirmer-donnees-cni.service.js';
import { SoumettreDoissierService } from './use-cases/soummetre-dossier-kyc.service.js';
import { ConsulterDossierService } from './use-cases/consulter-dossier.service.js';
import { DecisionAdminService } from './use-cases/decision-admin.service.js';
import { DemanderSignatureDocumentKycDto } from './dto/DemanderSignatureDocumentKyc.dto.js';
import { ConfirmerUploadDocumentKycDto } from './dto/confirmer-upload-document-kyc.dto.js';

@Controller()
export class KycController {
  constructor(
    private readonly uploadDocument: UploadDocumentService,
    private readonly extraireDonneesCni: ExtraireDonneesCniService,
    private readonly confirmerDonneesCni: ConfirmerDonneesCniService,
    private readonly soumettreDoissier: SoumettreDoissierService,
    private readonly consulterDossier: ConsulterDossierService,
    private readonly decisionAdmin: DecisionAdminService,
  ) {}

  // ── Documents KYC ─────────────────────────────────────────────────────────
  @Throttle({court:{ limit: 5, ttl: 60_000 }})
  @Vendeur()
  @Post('kyc/documents/signature')
  @HttpCode(HttpStatus.OK)
  demanderSignatureDocument(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: DemanderSignatureDocumentKycDto,
  ) {
    return this.uploadDocument.demanderSignature(u.id, dto);
  }

  @Vendeur()
  @Post('kyc/documents/confirmer')
  @HttpCode(HttpStatus.CREATED)
  confirmerDocument(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: ConfirmerUploadDocumentKycDto,
  ) {
    return this.uploadDocument.confirmerUpload( u.id, dto );
  }

  // ── OCR ───────────────────────────────────────────────────────────────────

  @Vendeur()
  @Post('kyc/cni/extraire')
  @HttpCode(HttpStatus.OK)
  extraireCni(@CurrentUser() u: UtilisateurConnecte) {
    return this.extraireDonneesCni.executer(u.id);
  }

  @Vendeur()
  @Post('kyc/cni/confirmer')
  @HttpCode(HttpStatus.OK)
  confirmerCni(
    @CurrentUser() u: UtilisateurConnecte,
    @Body() dto: DonneesCniDto,
  ) {
    return this.confirmerDonneesCni.executer(u.id, dto);
  }

  // ── Soumission ────────────────────────────────────────────────────────────

  @Vendeur()
  @RequiertIdempotenceKey()
  @Post('kyc/soumettre')
  @HttpCode(HttpStatus.OK)
  soumettre(@CurrentUser() u: UtilisateurConnecte) {
    return this.soumettreDoissier.executer(u.id);
  }

  // ── Consultation vendeur ──────────────────────────────────────────────────

  @Vendeur()
  @Get('kyc/mon-dossier')
  monDossier(@CurrentUser() u: UtilisateurConnecte) {
    return this.consulterDossier.pourVendeur(u.id);
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Get('admin/kyc')
  listerDossiers(
    @Query('statut') statut?: string,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.consulterDossier.listerPourAdmin({
      statut,
      page,
      limite: Math.min(limite, 50),
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