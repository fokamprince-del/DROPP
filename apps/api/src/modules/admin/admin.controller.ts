import {
  Body,
  Controller,
  Delete,
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

import {
  PrioriteSignalement,
  StatutCompte,
  StatutKyc,
  StatutSignalement,
  StatutVendeur,
} from '@dropp/database';
import { Admin } from '../auth/decorators/profils.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { ROLE, type RoleAdmin } from '../auth/roles.js';
import type { UtilisateurConnecte } from '../auth/types/utilisateur-connecte.js';

import { SuspendreUtilisateurDto } from './dto/suspendre-utilisateur.dto.js';
import { SuspendreVendeurDto } from './dto/suspendre-vendeur.dto.js';
import { AttribuerRoleDto } from './dto/attribuer-role.dto.js';
import { SupprimerUtilisateurDto } from './dto/supprimer-utilisateur.dto.js';
import {
  TraiterSignalementDto,
  TraiterSignalementService,
} from './use-cases/moderation/traiter-signalement.service.js';

import { ListerUtilisateursService } from './use-cases/utilisateurs/lister-utilisateurs.service.js';
import { DetailUtilisateurService } from './use-cases/utilisateurs/details-utilisateur.service.js';
import { SuspendreUtilisateurService } from './use-cases/utilisateurs/suspendre-utilisateur.service.js';
import { SupprimerUtilisateurService } from './use-cases/utilisateurs/supprimer-utilisateur.service.js';
import { ListerVendeursService } from './use-cases/vendeurs/lister-vendeurs.service.js';
import { SuspendreVendeurService } from './use-cases/vendeurs/suspendre-vendeur.service.js';
import { ListerSignalementsService } from './use-cases/moderation/lister-signalements.service.js';
import { AttribuerRoleService } from './use-cases/roles/attribuer-role.service.js';
import { RetirerRoleService } from './use-cases/roles/retirer-role.service.js';
import { StatsService } from './use-cases/dashboard/stats.service.js';
import { ListerAuditService } from './use-cases/audit/lister-audit.service.js';

const page = (p: number) => Math.max(p, 1);
const limite = (l: number, max = 100) => Math.min(Math.max(l, 1), max);
const filtreTexte = (v?: string) => v?.trim().slice(0, 100) || undefined;

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

  @Admin('SUPER_ADMIN', 'MODERATEUR', 'GESTIONNAIRE_FINANCIER')
  @Get('stats')
  obtenirStats() {
    return this.stats.executer();
  }

  // ── Utilisateurs ──────────────────────────────────────────────────────────

  @Admin('SUPER_ADMIN', 'MODERATEUR')
  @Get('utilisateurs')
  listeUtilisateurs(
    @Query('statut', new ParseEnumPipe(StatutCompte, { optional: true }))
    statut?: StatutCompte,
    @Query('recherche') recherche?: string,
    @Query('page', new ParseIntPipe({ optional: true })) p = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) l = 20,
  ) {
    return this.listerUtilisateurs.executer({
      statut,
      recherche: filtreTexte(recherche),
      page: page(p),
      limite: limite(l),
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

  /** POST plutôt que DELETE : un motif est exigé dans le corps. */
  @Admin('SUPER_ADMIN')
  @Post('utilisateurs/:id/supprimer')
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
    @Query('statut', new ParseEnumPipe(StatutVendeur, { optional: true }))
    statut?: StatutVendeur,
    @Query('statutKyc', new ParseEnumPipe(StatutKyc, { optional: true }))
    statutKyc?: StatutKyc,
    @Query('page', new ParseIntPipe({ optional: true })) p = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) l = 20,
  ) {
    return this.listerVendeurs.executer({
      statut,
      statutKyc,
      page: page(p),
      limite: limite(l),
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
    @Query('statut', new ParseEnumPipe(StatutSignalement, { optional: true }))
    statut?: StatutSignalement,
    @Query('priorite', new ParseEnumPipe(PrioriteSignalement, { optional: true }))
    priorite?: PrioriteSignalement,
    @Query('page', new ParseIntPipe({ optional: true })) p = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) l = 20,
  ) {
    return this.listerSignalements.executer({
      statut,
      priorite,
      page: page(p),
      limite: limite(l),
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
    @Param('role', new ParseEnumPipe(ROLE)) role: RoleAdmin,
  ) {
    return this.retirerRole.executer(id, role, u.id);
  }

  // ── Audit ─────────────────────────────────────────────────────────────────

  @Admin('SUPER_ADMIN')
  @Get('audit')
  audit(
    @Query('adminId', new ParseUUIDPipe({ optional: true })) adminId?: string,
    @Query('action') action?: string,
    @Query('resourceType') resourceType?: string,
    @Query('page', new ParseIntPipe({ optional: true })) p = 1,
    @Query('limite', new ParseIntPipe({ optional: true })) l = 50,
  ) {
    return this.listerAudit.executer({
      adminId,
      action: filtreTexte(action),
      resourceType: filtreTexte(resourceType),
      page: page(p),
      limite: limite(l),
    });
  }
}
