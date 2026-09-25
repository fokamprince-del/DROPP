import { Type } from 'class-transformer';
import { IsInt, Min } from 'class-validator';

export class ModifierArticlePanierDto {
  @IsInt()
  @Min(1)
  @Type(() => Number)
  quantite!: number;
}