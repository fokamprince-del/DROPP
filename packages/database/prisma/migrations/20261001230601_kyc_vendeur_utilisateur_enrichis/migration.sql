/*
  Warnings:

  - You are about to drop the column `banniere_cle` on the `boutiques` table. All the data in the column will be lost.
  - You are about to drop the column `logo_cle` on the `boutiques` table. All the data in the column will be lost.
  - You are about to drop the column `biographie` on the `vendeurs` table. All the data in the column will be lost.

*/
-- CreateEnum
CREATE TYPE "OperateurMobileMoney" AS ENUM ('MTN', 'ORANGE');

-- CreateEnum
CREATE TYPE "Sexe" AS ENUM ('MASCULIN', 'FEMININ', 'AUTRE');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "StatutKyc" ADD VALUE 'EN_COURS_VERIFICATION';
ALTER TYPE "StatutKyc" ADD VALUE 'EN_ATTENTE_REVUE_ADMIN';

-- AlterTable
ALTER TABLE "boutiques" DROP COLUMN "banniere_cle",
DROP COLUMN "logo_cle",
ADD COLUMN     "quartier" TEXT,
ADD COLUMN     "ville" TEXT;

-- AlterTable
ALTER TABLE "dossiers_kyc" ADD COLUMN     "date_etablissement" DATE,
ADD COLUMN     "date_expiration_cni" DATE,
ADD COLUMN     "date_naissance" DATE,
ADD COLUMN     "lieu_naissance" TEXT,
ADD COLUMN     "nom_legal" TEXT,
ADD COLUMN     "numero_cni" TEXT,
ADD COLUMN     "prenom_legal" TEXT,
ADD COLUMN     "score_face_match" DECIMAL(5,4);

-- AlterTable
ALTER TABLE "utilisateurs" ADD COLUMN     "sexe" "Sexe";

-- AlterTable
ALTER TABLE "vendeurs" DROP COLUMN "biographie",
ADD COLUMN     "numero_mobile_money" TEXT,
ADD COLUMN     "operateur_mobile_money" "OperateurMobileMoney";


-- Mobile Money cohérent
ALTER TABLE vendeurs
  ADD CONSTRAINT chk_vendeur_mobile_money_coherent
  CHECK (
    (numero_mobile_money IS NULL AND operateur_mobile_money IS NULL) OR
    (numero_mobile_money IS NOT NULL AND operateur_mobile_money IS NOT NULL)
  );

-- CNI non expirée à la soumission
ALTER TABLE dossiers_kyc
  ADD CONSTRAINT chk_kyc_cni_non_expiree
  CHECK (
    date_expiration_cni IS NULL OR
    date_expiration_cni > date_soumission
  );

-- Score face match entre 0 et 1
ALTER TABLE dossiers_kyc
  ADD CONSTRAINT chk_kyc_score_face_match
  CHECK (
    score_face_match IS NULL OR
    (score_face_match >= 0 AND score_face_match <= 1)
  );
