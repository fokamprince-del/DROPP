import type { ERREUR_CODES } from '@dropp/contrats';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { DroppExceptionParams } from './droppException.js';

export class ErreurApiDto {
  @ApiProperty({ type: Number, example: 404 })
  statusCode!: number;

  @ApiProperty({
    type: Object,
    oneOf: [{ type: 'string' }, { type: 'array', items: { type: 'string' } }],
    description: 'Texte, ou liste de messages pour une erreur de validation.',
    example: 'Produit introuvable.',
  })
  message!: string | string[];

  @ApiProperty({ type: String, example: 'PRODUCT_NOT_FOUND' })
  code!: ERREUR_CODES;

  @ApiPropertyOptional({ type: Object, description: 'Paramètres supplémentaires pour le message d’erreur.' })
  params?: DroppExceptionParams;

  @ApiPropertyOptional({ type: String, example: 'Not Found' })
  error?: string;
}