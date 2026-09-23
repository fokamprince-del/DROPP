import { IsInt, IsNotEmpty, IsString, IsUUID, Min } from 'class-validator';

export class ConfirmerMediaDto {
  /** Clé retournée par la signature d'upload. */
  @IsString()
  @IsNotEmpty()
  cleStockage!: string;

  @IsString()
  @IsNotEmpty()
  typeMime!: string;

  @IsInt()
  @Min(1)
  taille!: number;

  @IsUUID()
  produitId!: string;
}
