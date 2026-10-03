import { Injectable, Logger } from "@nestjs/common";
import { StockageProvider } from "./stockage.contract.js";

@Injectable()
export class StockageStubService implements StockageProvider {
    private readonly logger = new Logger(StockageStubService.name);
    async recupererBuffer(cleStockage: string): Promise<Buffer | null> {
        this.logger.debug(`[STOCKAGE STUB] Récupération du fichier — clé: ${cleStockage}`);
        return Buffer.from('stub-content');
    }
}