import { IsEnum } from 'class-validator';

export class AttribuerRoleDto {
  @IsEnum(['SUPER_ADMIN', 'MODERATEUR', 'GESTIONNAIRE_FINANCIER'])
  role!: string;
}