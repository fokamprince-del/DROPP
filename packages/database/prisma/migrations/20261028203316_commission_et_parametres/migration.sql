/*
  Warnings:

  - Added the required column `montant_commission` to the `sous_commandes` table without a default value. This is not possible if the table is not empty.
  - Added the required column `montant_net_vendeur` to the `sous_commandes` table without a default value. This is not possible if the table is not empty.
  - Added the required column `taux_commission` to the `sous_commandes` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "sous_commandes" ADD COLUMN     "montant_commission" DECIMAL(12,2) NOT NULL,
ADD COLUMN     "montant_net_vendeur" DECIMAL(12,2) NOT NULL,
ADD COLUMN     "taux_commission" DECIMAL(5,4) NOT NULL;

-- CreateTable
CREATE TABLE "parametres_plateforme" (
    "cle" TEXT NOT NULL,
    "valeur" JSONB NOT NULL,
    "date_modification" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "parametres_plateforme_pkey" PRIMARY KEY ("cle")
);


ALTER TABLE sous_commandes
  ADD CONSTRAINT chk_sous_commande_taux
    CHECK (taux_commission >= 0 AND taux_commission <= 1),
  ADD CONSTRAINT chk_sous_commande_commission
    CHECK (montant_commission >= 0
       AND montant_net_vendeur >= 0
       AND montant_commission + montant_net_vendeur = sous_total);