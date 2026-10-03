import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';

import { Admin } from '../auth/decorators/profils.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';

import { SuspendreUtilisateurDto } from './dto/suspendre-utilisateur.dto.js';
import { SuspendreVendeurDto } from './dto/suspendre-vendeur.dto.js';
import { AttribuerRoleDto } from './dto/attribuer-role.dto.js';
import { SupprimerUtilisateurDto } from './dto/supprimer-utilisateur.dto.js';
import { TraiterSignalementDto } from './use-cases/moderation/traiter-signalement.service.js';

import { ListerUtilisateursService } from './use-cases/utilisateurs/lister-utilisateurs.service.js';
import { DetailUtilisateurService } from './use-cases/utilisateurs/details-utilisateur.service.js';
import { SuspendreUtilisateurService } from './use-cases/utilisateurs/suspendre-utilisateur.service.js';
import { SupprimerUtilisateurService } from './use-cases/utilisateurs/supprimer-utilisateur.service.js';
import { ListerVendeursService } from './use-cases/vendeurs/lister-vendeurs.service.js';
import { SuspendreVendeurService } from './use-cases/vendeurs/suspendre-vendeur.service.js';
import { ListerSignalementsService } from './use-cases/moderation/lister-signalements.service.js';
import { TraiterSignalementService } from './use-cases/moderation/traiter-signalement.service.js';
import { AttribuerRoleService } from './use-cases/roles/attribuer-role.service.js';
import { RetirerRoleService } from './use-cases/roles/retirer-role.service.js';
import { StatsService } from './use-cases/dashboard/stats.service.js';
import { ListerAuditService } from './use-cases/audit/lister-audit.service.js';
import type { StatutCompte, StatutVendeur, StatutSignalement, PrioriteSignalement } from '@dropp/database';

@Controller('admin')
export class AdminController {
  constructor(
    private readonly listerUtilisateurs: ListerUtilisateursService,
    private readonly detailUtilisateur: DetailUtilisateurService,
    private readonly suspendreUtilisateur: SuspendreUtilisateurService,
    private readonly supprimerUtilisateur: SupprimerUtilisateurService,
    private readonly listerVendeurs: ListerVendeursService,
    private readonly suspendreVendeur: SuspendreVendeurService,
    private readonly listerSignalements: ListerSignalementsService,
    private readonly traiterSignalement: TraiterSignalementService,
    private readonly attribuerRole: AttribuerRoleService,
    private readonly retirerRole: RetirerRoleService,
    private readonly stats: StatsService,
    private readonly listerAudit: ListerAuditService,
  ) {}

  // ── Dashboard ─────────────────────────────────────────────────────────────

  @Admin()
  @Get('stats')
  obtenirStats() {
    return this.stats.executer();
  }

  // ── Utilisateurs ──────────────────────────────────────────────────────────

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Get('utilisateurs')
  listeUtilisateurs(
    @Query('statut') statut?: StatutCompte,
    @Query('recherche') recherche?: string,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.listerUtilisateurs.executer({
      statut,
      recherche,
      page,
      limite: Math.min(limite, 100),
    });
  }

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Get('utilisateurs/:id')
  voirUtilisateur(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.detailUtilisateur.executer(id, u.id);
  }

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Post('utilisateurs/:id/statut')
  @HttpCode(HttpStatus.OK)
  changerStatutUtilisateur(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SuspendreUtilisateurDto,
  ) {
    return this.suspendreUtilisateur.executer(
      id,
      u.id,
      dto.nouveauStatut,
      dto.raison,
    );
  }

  @Admin('SUPER_ADMIN')
  @Delete('utilisateurs/:id')
  @HttpCode(HttpStatus.OK)
  supprimerCompte(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SupprimerUtilisateurDto,
  ) {
    return this.supprimerUtilisateur.executer(id, u.id, dto.raison);
  }

  // ── Vendeurs ──────────────────────────────────────────────────────────────

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Get('vendeurs')
  listeVendeurs(
    @Query('statut') statut?: StatutVendeur,
    @Query('statutKyc') statutKyc?: string,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.listerVendeurs.executer({
      statut,
      statutKyc,
      page,
      limite: Math.min(limite, 100),
    });
  }

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Post('vendeurs/:id/statut')
  @HttpCode(HttpStatus.OK)
  changerStatutVendeur(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SuspendreVendeurDto,
  ) {
    return this.suspendreVendeur.executer(
      id,
      u.id,
      dto.nouveauStatut,
      dto.raison,
    );
  }

  // ── Modération ────────────────────────────────────────────────────────────

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Get('signalements')
  listeSignalements(
    @Query('statut') statut?: StatutSignalement,
    @Query('priorite') priorite?: PrioriteSignalement,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 20,
  ) {
    return this.listerSignalements.executer({
      statut,
      priorite,
      page,
      limite: Math.min(limite, 100),
    });
  }

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Post('signalements/:id/traiter')
  @HttpCode(HttpStatus.OK)
  traiter(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: TraiterSignalementDto,
  ) {
    return this.traiterSignalement.executer(id, u.id, dto);
  }

  // ── Rôles ─────────────────────────────────────────────────────────────────

  @Admin('SUPER_ADMIN')
  @Post('utilisateurs/:id/roles')
  @HttpCode(HttpStatus.OK)
  attribuer(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AttribuerRoleDto,
  ) {
    return this.attribuerRole.executer(id, dto.role, u.id);
  }

  @Admin('SUPER_ADMIN')
  @Delete('utilisateurs/:id/roles/:role')
  @HttpCode(HttpStatus.OK)
  retirer(
    @CurrentUser() u: UtilisateurConnecte,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('role') role: string,
  ) {
    return this.retirerRole.executer(id, role, u.id);
  }

  // ── Audit ─────────────────────────────────────────────────────────────────

  @Admin('SUPER_ADMIN')
  @Get('audit')
  audit(
    @Query('adminId') adminId?: string,
    @Query('action') action?: string,
    @Query('resourceType') resourceType?: string,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) limite = 50,
  ) {
    return this.listerAudit.executer({
      adminId,
      action,
      resourceType,
      page,
      limite: Math.min(limite, 100),
    });
  }
}