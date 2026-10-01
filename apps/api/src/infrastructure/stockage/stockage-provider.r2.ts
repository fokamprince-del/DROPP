import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  DeleteObjectCommand,
  GetObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
  S3ServiceException,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

import { estImage, genererCle } from './cle-stockage.js';
import {
  estCleePrivee,
  type MetadonneesFichier,
  type SignatureUpload,
  type StockageProvider,
} from './stockage-provider.contract.js';

/**
 * Cloudflare R2 via l'API compatible S3.
 * Upload : l'app fait un PUT direct sur l'URL signée (le fichier ne transite
 * pas par l'API). Lecture : URL publique du bucket (r2.dev ou domaine perso).
 */
@Injectable()
export class StockageProviderR2 implements StockageProvider {
  private readonly logger = new Logger(StockageProviderR2.name);
  private readonly client: S3Client;
  private readonly bucket: string;
  /** Bucket sans accès public (messagerie). */
  private readonly bucketPrive: string;
  private readonly urlPubliqueBase: string;
  private readonly ttlUploadSecondes: number;
  private readonly transformationsImages: boolean;

  constructor(config: ConfigService) {
    this.bucket = config.getOrThrow<string>('stockage.r2.bucket');
    this.bucketPrive = config.get<string>('stockage.r2.bucketPrive') || this.bucket;
    if (this.bucketPrive === this.bucket) {
      this.logger.warn(
        'R2_BUCKET_PRIVE non défini : les pièces jointes de messagerie sont dans le bucket public.',
      );
    }
    this.urlPubliqueBase = config
      .getOrThrow<string>('stockage.r2.publicUrl')
      .replace(/\/+$/, '');
    this.ttlUploadSecondes = config.getOrThrow<number>('stockage.r2.uploadUrlTtl');
    this.transformationsImages = config.get<boolean>(
      'stockage.r2.transformationsImages',
      false,
    );

    this.client = new S3Client({
      region: 'auto',
      endpoint: config.getOrThrow<string>('stockage.r2.endpoint'),
      credentials: {
        accessKeyId: config.getOrThrow<string>('stockage.r2.accessKeyId'),
        secretAccessKey: config.getOrThrow<string>('stockage.r2.secretAccessKey'),
      },
      // R2 ne gère pas les checksums CRC32 ajoutés par défaut par le SDK v3 :
      // sans ça, les URL signées contiennent des paramètres que l'app ne peut pas satisfaire.
      requestChecksumCalculation: 'WHEN_REQUIRED',
      responseChecksumValidation: 'WHEN_REQUIRED',
    });
  }

  async genererSignatureUpload(
    repertoire: string,
    typeMime: string,
    tailleMo: number,
  ): Promise<SignatureUpload> {
    const cleStockage = genererCle(repertoire, typeMime);
    const commande = new PutObjectCommand({
      Bucket: this.bucketPour(cleStockage),
      Key: cleStockage,
      ContentType: typeMime,
    });

    const uploadUrl = await getSignedUrl(this.client, commande, {
      expiresIn: this.ttlUploadSecondes,
      // Signés : l'app doit les renvoyer à l'identique.
      signableHeaders: new Set(['content-type']),
    });

    this.logger.debug(`Signature upload ${cleStockage} (max ${tailleMo} Mo)`);

    return {
      uploadUrl,
      cleStockage,
      expireA: new Date(Date.now() + this.ttlUploadSecondes * 1000),
      enTetes: { 'Content-Type': typeMime },
    };
  }

  urlPublique(
    cleStockage: string,
    options?: { largeur?: number; hauteur?: number },
  ): string {
    if (estCleePrivee(cleStockage) && this.bucketPrive !== this.bucket) {
      // Un fichier privé n'a pas d'URL publique : utiliser urlSignee().
      throw new Error(`Fichier privé sans URL publique : ${cleStockage}`);
    }
    const chemin = cleStockage.split('/').map(encodeURIComponent).join('/');

    // Redimensionnement Cloudflare Images : uniquement sur un domaine perso
    // (pas r2.dev) avec « Transformations » activées dans le dashboard.
    if (
      this.transformationsImages &&
      options &&
      (options.largeur || options.hauteur) &&
      estImage(cleStockage)
    ) {
      const params = [
        options.largeur && `width=${options.largeur}`,
        options.hauteur && `height=${options.hauteur}`,
        'fit=cover',
        'format=auto',
        'quality=85',
      ]
        .filter(Boolean)
        .join(',');
      return `${this.urlPubliqueBase}/cdn-cgi/image/${params}/${chemin}`;
    }

    return `${this.urlPubliqueBase}/${chemin}`;
  }

  async supprimer(cleStockage: string): Promise<void> {
    try {
      await this.client.send(
        new DeleteObjectCommand({ Bucket: this.bucketPour(cleStockage), Key: cleStockage }),
      );
    } catch (erreur) {
      this.logger.warn(`Suppression ${cleStockage} échouée : ${String(erreur)}`);
      throw erreur;
    }
  }

  async urlSignee(cleStockage: string, dureeSecondes = 3600): Promise<string> {
    return getSignedUrl(
      this.client,
      new GetObjectCommand({
        Bucket: this.bucketPour(cleStockage),
        Key: cleStockage,
      }),
      { expiresIn: dureeSecondes },
    );
  }

  private bucketPour(cleStockage: string): string {
    return estCleePrivee(cleStockage) ? this.bucketPrive : this.bucket;
  }

  async metadonnees(cleStockage: string): Promise<MetadonneesFichier | null> {
    try {
      const reponse = await this.client.send(
        new HeadObjectCommand({ Bucket: this.bucketPour(cleStockage), Key: cleStockage }),
      );
      return {
        taille: reponse.ContentLength ?? 0,
        typeMime: reponse.ContentType ?? null,
      };
    } catch (erreur) {
      if (
        erreur instanceof S3ServiceException &&
        (erreur.$metadata.httpStatusCode === 404 || erreur.name === 'NotFound')
      ) {
        return null;
      }
      throw erreur;
    }
  }
}
