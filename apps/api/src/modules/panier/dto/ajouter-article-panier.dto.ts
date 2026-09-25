import { Type } from 'class-transformer';
import { IsInt, IsUUID, Min } from 'class-validator';

export class AjouterArticlePanierDto {
  @IsUUID()
  varianteProduitId!: string;

  @IsInt()
  @Min(1)
  @Type(() => Number)
  quantite!: number;
}