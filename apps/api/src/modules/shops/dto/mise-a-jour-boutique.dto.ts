import { PartialType } from '@nestjs/common';

import { EnregistrerBoutiqueDto } from './enregistrer-boutique.dto.js';

export class MiseAJourBoutiqueDto extends PartialType(EnregistrerBoutiqueDto) {}
