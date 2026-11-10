import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../../infrastructure/database/prisma.service.js";
import { PlateformeAppareil } from "@dropp/database";

@Injectable()
export class AppareilService{
    constructor(
        private readonly prisma: PrismaService
    ){}

    async upsert(param:{
        modele: string, appareilId: string, utilisateurId: string, plateforme: PlateformeAppareil}): Promise<string>{
        const data = await this.prisma.appareil.upsert({
            create:{
                id: param.appareilId,
                plateforme: param.plateforme,
                utilisateurId: param.utilisateurId,
                modele: param.modele,
                tokenFcm: ''
            },
            update:{ modele: param.modele},
            where:{id:param.appareilId},
            select:{id: true}
        });

        return data.id
    }

    async dernierUtilisation(appareilId: string){
        await this.prisma.appareil.update({
            where: { id: appareilId },
            data:{ derniereUtilisation: new Date() }
        });
    }
}