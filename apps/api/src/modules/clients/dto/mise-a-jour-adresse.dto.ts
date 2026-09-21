import { PartialType } from '@nestjs/common';

import { CreerAdresseDto } from './creer-adresse.dto.js';

export class MiseAJourAdresseDto extends PartialType(CreerAdresseDto) {}
