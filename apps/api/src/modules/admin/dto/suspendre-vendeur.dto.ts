import { IsEnum, IsNotEmpty, IsString, MaxLength } from 'class-validator';
import type { StatutVendeur } from '@dropp/database';

export class SuspendreVendeurDto {
  @IsEnum(['ACTIF', 'SUSPENDU'])
  nouveauStatut!: Extract<StatutVendeur, 'ACTIF' | 'SUSPENDU'>;

  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  raison!: string;
}