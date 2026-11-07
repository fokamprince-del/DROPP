import { Module } from "@nestjs/common";
import { STOCKAGE_PROVIDER, StockageProvider } from "./stockage.contract.js";
import { ConfigService } from "@nestjs/config";
import { StockageService } from "./stockage.service.js";
import { StockageStubService } from "./stockage.stup.js";

@Module({
    providers: [
        {
            provide: STOCKAGE_PROVIDER,
            inject: [ConfigService],
            useFactory: (config: ConfigService): StockageProvider => {
                const driver = config.get<string>("stockage.driver", "stub");
                if(driver == "r2") 
                    return new StockageService(config);
                if(config.get<string>("app.environment") === "production") {
                    throw new Error("STOCKAGE_DRIVER=stub interdit en production.");
                }
                return new StockageStubService();
            }
        }
    ],
    exports: [STOCKAGE_PROVIDER],
})
export class StockageModule {}