import { IsIn, IsInt, IsNotEmpty, IsString, Max, Min } from 'class-validator';

const TYPES_MIME_AUTORISES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'video/mp4',
  'video/quicktime',
] as const;

export class DemanderSignaturePublicationDto {
  @IsString()
  @IsNotEmpty()
  @IsIn(TYPES_MIME_AUTORISES)
  typeMime!: string;

  @IsInt()
  @Min(1)
  @Max(500 * 1024 * 1024)
  taille!: number;
}
