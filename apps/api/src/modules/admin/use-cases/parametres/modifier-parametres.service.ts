// modifier-parametre.service.ts
import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import { ParametresService } from '../../../parametres/parametres.service.js';
import {
  PARAMETRES, erreurValeur, estCleParametre, resoudre,
} from '../../../parametres/parametres.registre.js';
import type { ParametreDto } from '../../dto/parametres.dto.js';

@Injectable()
export class ModifierParametreService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly parametres: ParametresService,
  ) {}

  async executer(cle: string, valeur: number, adminId: string): Promise<ParametreDto> {
    if (!estCleParametre(cle)) throw new NotFoundException('Paramètre inconnu.');

    const erreur = erreurValeur(cle, valeur);
    if (erreur) throw new BadRequestException(erreur);

    const existant = await this.prisma.parametrePlateforme.findUnique({
      where: { cle },
      select: { valeur: true },
    });
    const ancienne = typeof existant?.valeur === 'number' ? existant.valeur : PARAMETRES[cle].defaut;

    await this.prisma.$transaction([
      this.prisma.parametrePlateforme.upsert({
        where: { cle },
        create: { cle, valeur },
        update: { valeur },
      }),
      this.prisma.journalAudit.create({
        data: {
          administrateurId: adminId,
          action: 'MODIFIER_PARAMETRE',
          resourceType: 'ParametrePlateforme',
          resourceId: cle,
          details: { ancienne, nouvelle: valeur },
        },
      }),
    ]);

    await this.parametres.invalider(cle); // après le commit, pas avant

    return resoudre(cle, valeur);
  }
}