import { Type } from 'class-transformer';
import { IsInt, Max, Min } from 'class-validator';

export class ModifierArticlePanierDto {
  @IsInt()
  @Min(1)
  @Max(1_000)
  @Type(() => Number)
  quantite!: number;
}
