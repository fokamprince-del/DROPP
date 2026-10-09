import { Type } from 'class-transformer';
import { IsInt, IsUUID, Max, Min } from 'class-validator';

export class AjouterArticlePanierDto {
  @IsUUID()
  varianteProduitId!: string;

  @IsInt()
  @Min(1)
  @Max(1_000)
  @Type(() => Number)
  quantite!: number;
}
