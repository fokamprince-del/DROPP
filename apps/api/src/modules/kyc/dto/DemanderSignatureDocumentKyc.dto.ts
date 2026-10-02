import { TypeDocumentKyc } from "@dropp/database";
import { IsString, IsNotEmpty, IsIn, IsInt, Min, Max } from "class-validator";

export const TYPES_MIME_KYC_AUTORISES = [
    'image/jpeg', 
    'image/png', 
    'image/webp'
] ;

export const MAX_TAILLE_DOCUMENT_KYC = 10 * 1024 * 1024; // 10 Mo

export class DemanderSignatureDocumentKycDto {
    @IsString()
    @IsNotEmpty()
    @IsIn(TYPES_MIME_KYC_AUTORISES)
    typeMime!: string;

    @IsInt()
    @Min(1)
    @Max(MAX_TAILLE_DOCUMENT_KYC)
    taille!: number;

    @IsIn(Object.values(TypeDocumentKyc))
    typeDocument!: TypeDocumentKyc;
}