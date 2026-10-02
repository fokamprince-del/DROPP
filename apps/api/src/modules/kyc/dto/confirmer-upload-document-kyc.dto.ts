import { IsIn, IsInt, IsNotEmpty, IsString, Max, Min } from "class-validator";
import { MAX_TAILLE_DOCUMENT_KYC } from "./DemanderSignatureDocumentKyc.dto.js";
import { TypeDocumentKyc } from "@dropp/database";

export class ConfirmerUploadDocumentKycDto {
    @IsString()
    @IsNotEmpty()
    cleStockage!: string;

    @IsString()
    @IsNotEmpty()
    typeMime!: string;

    @IsInt()
    @Min(1)
    @Max(MAX_TAILLE_DOCUMENT_KYC)
    taille!: number;

    @IsIn(Object.values(TypeDocumentKyc))
    typeDocument!: TypeDocumentKyc;
}