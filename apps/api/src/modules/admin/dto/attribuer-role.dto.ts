import { IsIn } from 'class-validator';

import { ROLES_ADMIN, type RoleAdmin } from '../../auth/roles.js';

export class AttribuerRoleDto {
  @IsIn(ROLES_ADMIN)
  role!: RoleAdmin;
}
