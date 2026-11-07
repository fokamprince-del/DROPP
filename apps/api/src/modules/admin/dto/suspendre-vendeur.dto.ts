import { Transform } from 'class-transformer';
import { IsEnum, IsNotEmpty, IsString, MaxLength } from 'class-validator';
import type { StatutVendeur } from '@dropp/database';

export class SuspendreVendeurDto {
  @IsEnum(['ACTIF', 'SUSPENDU'])
  nouveauStatut!: Extract<StatutVendeur, 'ACTIF' | 'SUSPENDU'>;

  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsNotEmpty()
  @MaxLength(500)
  raison!: string;
}