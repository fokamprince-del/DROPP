import { Transform } from 'class-transformer';
import {
	IsBoolean,
	IsEnum,
	IsLatitude,
	IsLongitude,
	IsOptional,
	IsString,
	MaxLength,
} from 'class-validator';

import { TypeAdresse } from '../../../generated/prisma/client.js';

export class MiseAJourAdresseDto {
	@IsOptional()
	@IsEnum(TypeAdresse)
	type?: TypeAdresse;

	@IsOptional()
	@IsString()
	@Transform(({ value }) =>
		typeof value === 'string' ? value.trim() : value,
	)
	@MaxLength(255)
	ligne1?: string;

	@IsOptional()
	@IsString()
	@Transform(({ value }) =>
		typeof value === 'string' ? value.trim() : value,
	)
	@MaxLength(255)
	ligne2?: string;

	@IsOptional()
	@IsString()
	@Transform(({ value }) =>
		typeof value === 'string' ? value.trim() : value,
	)
	@MaxLength(100)
	ville?: string;

	@IsOptional()
	@IsString()
	@Transform(({ value }) =>
		typeof value === 'string' ? value.trim() : value,
	)
	@MaxLength(100)
	region?: string;

	@IsOptional()
	@IsString()
	@Transform(({ value }) =>
		typeof value === 'string' ? value.trim() : value,
	)
	@MaxLength(100)
	pays?: string;

	@IsOptional()
	@IsString()
	@Transform(({ value }) =>
		typeof value === 'string' ? value.trim() : value,
	)
	@MaxLength(20)
	codePostal?: string;

	@IsOptional()
	@IsLatitude()
	latitude?: number;

	@IsOptional()
	@IsLongitude()
	longitude?: number;

	@IsOptional()
	@IsBoolean()
	estPrincipale?: boolean;
}
