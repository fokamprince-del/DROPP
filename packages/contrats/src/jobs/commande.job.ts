export const QUEUE_COMMANDE = 'commande' as const;

export const JOB_COMMANDE = {
  EXPIRATION_PASSAGE: 'commande.expiration',
  /** Planifié : rattrape les expirations dont le job différé a été perdu. */
  BALAYAGE_EXPIRATIONS: 'commande.balayage-expirations',
  LIBERATION_STOCK: 'stock.liberation',
} as const;

export type JobExpirationPassage = {
  passageCommandeId: string;
};

export type JobLiberationStock = {
  reservationStockId: string;
};
