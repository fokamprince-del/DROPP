import { PartialType } from '@nestjs/common';

import { CreerCategorieDto } from './creer-categorie.dto.js';

export class MiseAJourCategorieDto extends PartialType(CreerCategorieDto) {}
