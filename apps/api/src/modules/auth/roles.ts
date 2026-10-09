/** Rôles d'administration (table `roles`, insérés par migration). */
export const ROLE = {
  SUPER_ADMIN: 'SUPER_ADMIN',
  MODERATEUR: 'MODERATEUR',
  GESTIONNAIRE_FINANCIER: 'GESTIONNAIRE_FINANCIER',
} as const;

export type RoleAdmin = (typeof ROLE)[keyof typeof ROLE];

export const ROLES_ADMIN = Object.values(ROLE);
