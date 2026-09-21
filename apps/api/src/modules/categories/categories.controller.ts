import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  ParseEnumPipe,
  UseGuards,
} from '@nestjs/common';

import { Public } from '../auth/decorators/public.decorator.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { AuthentificationGuard } from '../auth/guards/auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
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
  @UseGuards(AuthentificationGuard, RolesGuard)
  @Roles('ADMIN')
  listerAdministration() {
    return this.categoriesService.listerAdministration();
  }

  @Post()
  @UseGuards(AuthentificationGuard, RolesGuard)
  @Roles('ADMIN')
  creer(@Body() dto: CreerCategorieDto) {
    return this.categoriesService.creer(dto);
  }

  @Patch(':id')
  @UseGuards(AuthentificationGuard, RolesGuard)
  @Roles('ADMIN')
  mettreAJour(
    @Param('id') id: string,
    @Body() dto: MiseAJourCategorieDto,
  ) {
    return this.categoriesService.mettreAJour(id, dto);
  }

  @Patch(':id/statut/:statut')
  @UseGuards(AuthentificationGuard, RolesGuard)
  @Roles('ADMIN')
  changerStatut(
    @Param('id') id: string,
    @Param('statut', new ParseEnumPipe(StatutCategorie))
    statut: StatutCategorie,
  ) {
    return this.categoriesService.changerStatut(id, statut);
  }
}
