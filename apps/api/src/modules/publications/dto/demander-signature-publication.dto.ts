import { IsIn, IsInt, Max, Min } from 'class-validator';

import {
  TAILLE_MAX_MEDIA_OCTETS,
  TYPES_MIME_MEDIA,
} from '../../../infrastructure/stockage/media.js';

export class DemanderSignaturePublicationDto {
  @IsIn(TYPES_MIME_MEDIA)
  typeMime!: string;

  @IsInt()
  @Min(1)
  @Max(TAILLE_MAX_MEDIA_OCTETS)
  taille!: number;
}
