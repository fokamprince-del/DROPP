import { Module } from '@nestjs/common';
import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { AdminController } from './admin.controller.js';

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

@Module({
  imports: [PrismaModule],
  controllers: [AdminController],
  providers: [
    ListerUtilisateursService,
    DetailUtilisateurService,
    SuspendreUtilisateurService,
    SupprimerUtilisateurService,
    ListerVendeursService,
    SuspendreVendeurService,
    ListerSignalementsService,
    TraiterSignalementService,
    AttribuerRoleService,
    RetirerRoleService,
    StatsService,
    ListerAuditService,
  ],
})
export class AdminModule {}