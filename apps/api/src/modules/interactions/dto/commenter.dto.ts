import { Transform } from 'class-transformer';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CommenterDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  @Transform(({ value }: { value: string }) => value?.trim())
  contenu!: string;

  /** Présent uniquement pour une réponse à un commentaire racine. */
  @IsOptional()
  @IsUUID()
  parentId?: string;
}
