/*
  Warnings:

  - The values [DESACTIVE] on the enum `StatutClient` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `photo_profil_url` on the `utilisateurs` table. All the data in the column will be lost.
  - You are about to drop the `journaux_audit` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `reinitialisations_mots_de_passe` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[jeton_rafraichissement_hash]` on the table `sessions` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `canal` to the `codes_verification` table without a default value. This is not possible if the table is not empty.
  - Added the required column `methode_auth` to the `sessions` table without a default value. This is not possible if the table is not empty.
  - Added the required column `date_modification` to the `utilisateurs` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "TypeEvenementSecurite" AS ENUM ('INSCRIPTION', 'VERIFICATION_TELEPHONE', 'CONNEXION_REUSSIE', 'CONNEXION_ECHOUEE', 'DECONNEXION', 'REFRESH_TOKEN', 'REFRESH_REJETE', 'MOT_DE_PASSE_CHANGE', 'TELEPHONE_CHANGE', 'EMAIL_CHANGE', 'COMPTE_VERROUILLE', 'REINITIALISATION_MDP_DEMANDEE', 'REINITIALISATION_MDP_EFFECTUEE', 'SESSION_REVOQUEE', 'TOUTES_SESSIONS_REVOQUEES');

-- CreateEnum
CREATE TYPE "CanalVerification" AS ENUM ('SMS', 'EMAIL');

-- CreateEnum
CREATE TYPE "MethodeAuthentification" AS ENUM ('TELEPHONE_MDP', 'EMAIL_MDP', 'GOOGLE', 'APPLE');

-- CreateEnum
CREATE TYPE "FournisseurIdentite" AS ENUM ('GOOGLE', 'APPLE');

-- AlterEnum
BEGIN;
CREATE TYPE "StatutClient_new" AS ENUM ('ACTIF', 'SUSPENDU');
ALTER TABLE "public"."clients" ALTER COLUMN "statutClient" DROP DEFAULT;
ALTER TABLE "clients" ALTER COLUMN "statutClient" TYPE "StatutClient_new" USING ("statutClient"::text::"StatutClient_new");
ALTER TYPE "StatutClient" RENAME TO "StatutClient_old";
ALTER TYPE "StatutClient_new" RENAME TO "StatutClient";
DROP TYPE "public"."StatutClient_old";
ALTER TABLE "clients" ALTER COLUMN "statutClient" SET DEFAULT 'ACTIF';
COMMIT;

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "TypeCodeVerification" ADD VALUE 'VERIFICATION_NOUVEAU_TELEPHONE';
ALTER TYPE "TypeCodeVerification" ADD VALUE 'VERIFICATION_EMAIL';

-- DropForeignKey
ALTER TABLE "journaux_audit" DROP CONSTRAINT "journaux_audit_administrateur_id_fkey";

-- DropForeignKey
ALTER TABLE "reinitialisations_mots_de_passe" DROP CONSTRAINT "reinitialisations_mots_de_passe_utilisateur_id_fkey";

-- AlterTable
ALTER TABLE "codes_verification" ADD COLUMN     "canal" "CanalVerification" NOT NULL,
ADD COLUMN     "cooldown_fin" TIMESTAMPTZ(3);

-- AlterTable
ALTER TABLE "sessions" ADD COLUMN     "methode_auth" "MethodeAuthentification" NOT NULL;

-- AlterTable
ALTER TABLE "utilisateurs" DROP COLUMN "photo_profil_url",
ADD COLUMN     "date_modification" TIMESTAMPTZ(3) NOT NULL,
ADD COLUMN     "email_verifie_le" TIMESTAMPTZ(3),
ADD COLUMN     "telephone_verifie_le" TIMESTAMPTZ(3),
ALTER COLUMN "email" DROP NOT NULL,
ALTER COLUMN "telephone" DROP NOT NULL,
ALTER COLUMN "mot_de_passe_hash" DROP NOT NULL;

-- DropTable
DROP TABLE "journaux_audit";

-- DropTable
DROP TABLE "reinitialisations_mots_de_passe";

-- DropEnum
DROP TYPE "FournisseurAuthentification";

-- DropEnum
DROP TYPE "RoleUtilisateur";

-- CreateTable
CREATE TABLE "journaux_securite" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID,
    "evenement" "TypeEvenementSecurite" NOT NULL,
    "adresse_ip" TEXT,
    "appareil_id" UUID,
    "details" JSONB,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "journaux_securite_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "identites_externes" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "fournisseur" "FournisseurIdentite" NOT NULL,
    "sujet" TEXT NOT NULL,
    "email" TEXT,
    "email_verifie" BOOLEAN NOT NULL DEFAULT false,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "identites_externes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "journaux_securite_utilisateur_id_idx" ON "journaux_securite"("utilisateur_id");

-- CreateIndex
CREATE INDEX "journaux_securite_evenement_idx" ON "journaux_securite"("evenement");

-- CreateIndex
CREATE INDEX "journaux_securite_date_creation_idx" ON "journaux_securite"("date_creation");

-- CreateIndex
CREATE UNIQUE INDEX "identites_externes_fournisseur_sujet_key" ON "identites_externes"("fournisseur", "sujet");

-- CreateIndex
CREATE UNIQUE INDEX "identites_externes_utilisateur_id_fournisseur_key" ON "identites_externes"("utilisateur_id", "fournisseur");

-- CreateIndex
CREATE UNIQUE INDEX "sessions_jeton_rafraichissement_hash_key" ON "sessions"("jeton_rafraichissement_hash");

-- AddForeignKey
ALTER TABLE "journaux_securite" ADD CONSTRAINT "journaux_securite_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "identites_externes" ADD CONSTRAINT "identites_externes_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- Contraintes CHECK
ALTER TABLE utilisateurs ADD CONSTRAINT chk_identifiant_present
  CHECK (email IS NOT NULL OR telephone IS NOT NULL);
ALTER TABLE utilisateurs ADD CONSTRAINT chk_email_normalise
  CHECK (email IS NULL OR email = lower(email));
ALTER TABLE utilisateurs ADD CONSTRAINT chk_telephone_verifie_coherent
  CHECK (telephone_verifie_le IS NULL OR telephone IS NOT NULL);
ALTER TABLE utilisateurs ADD CONSTRAINT chk_email_verifie_coherent
  CHECK (email_verifie_le IS NULL OR email IS NOT NULL);
ALTER TABLE utilisateurs ADD CONSTRAINT chk_mdp_requiert_identifiant
  CHECK (mot_de_passe_hash IS NULL OR telephone IS NOT NULL OR email IS NOT NULL);
ALTER TABLE utilisateurs ADD CONSTRAINT chk_actif_telephone_verifie
  CHECK (statut_compte <> 'ACTIF' OR telephone_verifie_le IS NOT NULL);
ALTER TABLE vendeurs ADD CONSTRAINT chk_commission_entre_0_et_1
  CHECK (commission_personnalisee IS NULL
    OR (commission_personnalisee >= 0 AND commission_personnalisee <= 1));
ALTER TABLE codes_verification ADD CONSTRAINT chk_tentatives_positives
  CHECK (nombre_tentatives >= 0);
ALTER TABLE identites_externes ADD CONSTRAINT chk_sujet_non_vide
  CHECK (length(sujet) > 0);

-- Invariant profil + seed rôles (même SQL que précédemment, déjà validé)