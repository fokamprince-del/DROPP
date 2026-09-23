import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  ParseEnumPipe,
} from '@nestjs/common';

import { Admin } from '../auth/decorators/profils.decorator.js';
import { Public } from '../auth/decorators/public.decorator.js';
import { CreerCategorieDto } from './dto/creer-categorie.dto.js';
import { MiseAJourCategorieDto } from './dto/mise-a-jour-categorie.dto.js';
import { CategoriesService } from './categories.service.js';
import { StatutCategorie } from '../../generated/prisma/client.js';

@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Public()
  @Get()
  listerPubliques() {
    return this.categoriesService.listerPubliques();
  }

  @Get('admin')
  @Admin('ADMIN')
  listerAdministration() {
    return this.categoriesService.listerAdministration();
  }

  @Post()
  @Admin('ADMIN')
  creer(@Body() dto: CreerCategorieDto) {
    return this.categoriesService.creer(dto);
  }

  @Patch(':id')
  @Admin('ADMIN')
  mettreAJour(
    @Param('id') id: string,
    @Body() dto: MiseAJourCategorieDto,
  ) {
    return this.categoriesService.mettreAJour(id, dto);
  }

  @Patch(':id/statut/:statut')
  @Admin('ADMIN')
  changerStatut(
    @Param('id') id: string,
    @Param('statut', new ParseEnumPipe(StatutCategorie))
    statut: StatutCategorie,
  ) {
    return this.categoriesService.changerStatut(id, statut);
  }
}
