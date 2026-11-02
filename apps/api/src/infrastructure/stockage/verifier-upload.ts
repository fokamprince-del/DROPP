import { BadRequestException } from '@nestjs/common';

import type {
  MetadonneesFichier,
  StockageProvider,
} from './stockage-provider.contract.js';
import { DroppException } from '../http/droppException.js';
import { UPLOAD_ERRORS } from '@dropp/contrats';

/**
 * Contrôle d'un fichier annoncé comme uploadé par l'app, avant de l'enregistrer :
 * - la clé vient bien d'une signature émise pour ce dossier (pas le fichier d'un autre) ;
 * - le fichier existe réellement dans le bucket ;
 * - sa taille et son type RÉELS respectent les limites (ceux déclarés par l'app
 *   ne sont pas fiables : une URL signée ne borne pas la taille envoyée).
 *
 * Un fichier hors limites est supprimé du bucket.
 */
export async function verifierUpload(
  stockage: StockageProvider,
  params: {
    cleStockage: string;
    prefixe: string;
    tailleMaxMo: number;
    /** Types acceptés (le type réel stocké dans R2 doit en faire partie). */
    typesMime: readonly string[];
  },
): Promise<MetadonneesFichier> {
  const { cleStockage, prefixe, tailleMaxMo, typesMime } = params;
  const prefixeNormalise = prefixe.endsWith('/') ? prefixe : `${prefixe}/`;

  if (
    !cleStockage.startsWith(prefixeNormalise) ||
    cleStockage.includes('..') ||
    cleStockage.includes('//')
  ) {
    throw DroppException.BadRequest('Fichier invalide pour cette ressource.', UPLOAD_ERRORS.INVALID_STORAGE_KEY);
  }

  const meta = await stockage.metadonnees(cleStockage);
  if (!meta) {
    throw DroppException.BadRequest('Fichier introuvable : upload non terminé.', UPLOAD_ERRORS.UPLOAD_NOT_FOUND);
  }

  if (meta.taille > tailleMaxMo * 1024 * 1024) {
    await stockage.supprimer(cleStockage).catch(() => undefined);
    throw DroppException.BadRequest(
      `Fichier trop volumineux. Maximum `,
      UPLOAD_ERRORS.FILE_TOO_LARGE,
      {
        tailleMaxMo,
        taille: meta.taille,
      }
    );
  }

  if (meta.typeMime && !typesMime.includes(meta.typeMime)) {
    await stockage.supprimer(cleStockage).catch(() => undefined);
    throw DroppException.BadRequest('Type de fichier incohérent.', UPLOAD_ERRORS.FILE_TYPE_MISMATCH, {
      typeMime: meta.typeMime,
      typesMimeAutorises: [...typesMime] ,
    });
  }

  await stockage.marquerUtilise?.(cleStockage);
  return meta;
}
