export const QUEUE_MEDIA = 'media' as const;

export const JOB_MEDIA = {
  TRAITEMENT_VIDEO: 'media.traitement-video',
} as const;

export type JobTraitementVideo = {
  mediaId: string;
  cleStockage: string;
  typeMime: string;
};