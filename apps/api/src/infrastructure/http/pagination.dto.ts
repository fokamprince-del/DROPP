import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PaginationDto {
  @ApiProperty({ type: 'integer' }) total!: number;
  @ApiProperty({ type: 'integer' }) page!: number;
  @ApiProperty({ type: 'integer' }) pages!: number;
}

/** Fabrique une page typée : `class PageXDto extends PageDe(XDto) {}`. */
export function PageDe<T extends new (...args: any[]) => any>(element: T) {
  class Page {
    @ApiProperty({ type: [element] })
    donnees!: InstanceType<T>[];

    @ApiProperty({ type: PaginationDto })
    pagination!: PaginationDto;
  }
  return Page;
}

/** `limite` > 100 donne désormais un 400 au lieu d'être tronquée en silence. */
export class PaginationQueryDto {
  @ApiPropertyOptional({ type: 'integer', minimum: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ type: 'integer', minimum: 1, maximum: 100, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limite: number = 20;
}