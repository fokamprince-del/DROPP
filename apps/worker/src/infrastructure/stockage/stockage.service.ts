import { Injectable, Logger } from "@nestjs/common";
import { estCleePrivee, StockageProvider } from "./stockage.contract.js";
import { S3Client, S3ServiceException, GetObjectCommand } from "@aws-sdk/client-s3";
import { ConfigService } from "@nestjs/config";

@Injectable()
export class StockageService implements StockageProvider {
    private readonly logger = new Logger(StockageService.name);
    private readonly client: S3Client;
    private readonly bucket: string;
    private readonly bucketPrive: string;

    constructor(config: ConfigService) {
        this.bucket = config.getOrThrow<string>("stockage.r2.bucket");
        this.bucketPrive = config.get<string>("stockage.r2.bucketPrive") || this.bucket;
        if(this.bucketPrive === this.bucket) {
            this.logger.warn("R2_BUCKET_PRIVE non défini : les documents privés sont dans le bucket public.");
        }
        this.client = new S3Client({
            region: "auto",
            endpoint: config.getOrThrow<string>("stockage.r2.endpoint"),
            credentials: {
                accessKeyId: config.getOrThrow<string>("stockage.r2.accessKeyId"),
                secretAccessKey: config.getOrThrow<string>("stockage.r2.secretAccessKey"),
            },
            requestChecksumCalculation: 'WHEN_REQUIRED',
            responseChecksumValidation: 'WHEN_REQUIRED',
        });
    }

    async recupererBuffer(cleStockage: string): Promise<Buffer | null> {
        try{
        const reponse = await this.client.send( 
            new GetObjectCommand({ Bucket: this.bucketPour(cleStockage), Key: cleStockage }),
        );

        if(!reponse.Body)
            return null;

        const chunks = await reponse.Body.transformToByteArray();
        return Buffer.from(chunks);
        }catch(erreur){
        if (
            erreur instanceof S3ServiceException &&
            (erreur.$metadata.httpStatusCode === 404 || erreur.name === 'NotFound')
        ) {
            return null;
        }
        throw erreur;
        }

    }

    private bucketPour(cleStockage: string): string {
    return estCleePrivee(cleStockage) ? this.bucketPrive : this.bucket;
  }

}