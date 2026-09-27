import { SetMetadata } from '@nestjs/common';

export const CLE_ROLES_ADMIN = 'roles_admin_requis';

/**
 * Exige que l'utilisateur possède au moins un des rôles d'administration listés.
 * Relit toujours la base : un rôle retiré prend effet immédiatement,
 * sans attendre l'expiration du JWT.
 *
 * @example
 * @RequiertRoleAdmin('SUPER_ADMIN', 'MODERATEUR')
 * @Get('admin/signalements')
 */
export const RequiertRoleAdmin = (...roles: string[]) =>
  SetMetadata(CLE_ROLES_ADMIN, roles);
