import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, Max, Min } from 'class-validator';

export class AjusterStockDto {
  /**
   * Quantité à ajouter (positive) ou retirer (négative).
   * Max ±10 000 par opération pour éviter les erreurs de saisie.
   */
  @IsInt()
  @Min(-10_000)
  @Max(10_000)
  @Type(() => Number)
  delta!: number;

  @IsString()
  @IsNotEmpty()
  raison!: string;
}