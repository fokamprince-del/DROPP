import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsIn,
  ValidateNested,
} from 'class-validator';

import type { TypeNotification } from '@dropp/database';
import { TYPES_CONFIGURABLES } from '../notifications.service.js';

export class PreferenceDto {
  @IsIn(TYPES_CONFIGURABLES)
  type!: (typeof TYPES_CONFIGURABLES)[number] & TypeNotification;

  @IsBoolean()
  active!: boolean;
}

export class ModifierPreferencesDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(TYPES_CONFIGURABLES.length)
  @ValidateNested({ each: true })
  @Type(() => PreferenceDto)
  preferences!: PreferenceDto[];
}
