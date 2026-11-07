import { Transform } from 'class-transformer';
import { IsEnum, IsNotEmpty, IsString, MaxLength } from 'class-validator';
import type { StatutCompte } from '@dropp/database';

export class SuspendreUtilisateurDto {
  @IsEnum(['ACTIF', 'SUSPENDU_TEMP', 'SUSPENDU_DEF'])
  nouveauStatut!: Extract<StatutCompte, 'ACTIF' | 'SUSPENDU_TEMP' | 'SUSPENDU_DEF'>;

  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsNotEmpty()
  @MaxLength(500)
  raison!: string;
}