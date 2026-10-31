// lister-parametres.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../../infrastructure/database/prisma.service.js';
import { PARAMETRES, resoudre, type CleParametre } from '../../../parametres/parametres.registre.js';
import type { ParametreDto } from '../../dto/parametres.dto.js';

@Injectable()
export class ListerParametresService {
  constructor(private readonly prisma: PrismaService) {}

  async executer(): Promise<ParametreDto[]> {
    const lignes = await this.prisma.parametrePlateforme.findMany({
      select: { cle: true, valeur: true },
    });
    const enBase = new Map(lignes.map((l) => [l.cle, l.valeur]));
    return (Object.keys(PARAMETRES) as CleParametre[]).map((cle) => resoudre(cle, enBase.get(cle)));
  }
}