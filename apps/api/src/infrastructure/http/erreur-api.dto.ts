import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

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

  @ApiPropertyOptional({ type: String, example: 'Not Found' })
  error?: string;
}