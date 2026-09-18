-- CreateEnum
CREATE TYPE "TypeCodeVerification" AS ENUM ('INSCRIPTION', 'REINITIALISATION_MOT_DE_PASSE');

-- AlterEnum
BEGIN;
CREATE TYPE "MoyenPaiement_new" AS ENUM ('MOBILE_MONEY_MTN', 'MOBILE_MONEY_ORANGE');
ALTER TABLE "paiements" ALTER COLUMN "moyen_paiement" TYPE "MoyenPaiement_new" USING ("moyen_paiement"::text::"MoyenPaiement_new");
ALTER TYPE "MoyenPaiement" RENAME TO "MoyenPaiement_old";
ALTER TYPE "MoyenPaiement_new" RENAME TO "MoyenPaiement";
DROP TYPE "public"."MoyenPaiement_old";
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "TypeConversation_new" AS ENUM ('DIRECTE');
ALTER TABLE "conversations" ALTER COLUMN "type" TYPE "TypeConversation_new" USING ("type"::text::"TypeConversation_new");
ALTER TYPE "TypeConversation" RENAME TO "TypeConversation_old";
ALTER TYPE "TypeConversation_new" RENAME TO "TypeConversation";
DROP TYPE "public"."TypeConversation_old";
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "TypeMessage_new" AS ENUM ('TEXTE', 'IMAGE', 'VIDEO', 'FICHIER');
ALTER TABLE "messages" ALTER COLUMN "type" TYPE "TypeMessage_new" USING ("type"::text::"TypeMessage_new");
ALTER TYPE "TypeMessage" RENAME TO "TypeMessage_old";
ALTER TYPE "TypeMessage_new" RENAME TO "TypeMessage";
DROP TYPE "public"."TypeMessage_old";
COMMIT;

-- DropForeignKey
ALTER TABLE "_PortefeuilleToUtilisateur" DROP CONSTRAINT "_PortefeuilleToUtilisateur_A_fkey";

-- DropForeignKey
ALTER TABLE "_PortefeuilleToUtilisateur" DROP CONSTRAINT "_PortefeuilleToUtilisateur_B_fkey";

-- DropForeignKey
ALTER TABLE "adresses" DROP CONSTRAINT "adresses_utilisateur_id_fkey";

-- DropForeignKey
ALTER TABLE "articles_commandes" DROP CONSTRAINT "articles_commandes_commande_id_fkey";

-- DropForeignKey
ALTER TABLE "articles_commandes" DROP CONSTRAINT "articles_commandes_vendeur_id_fkey";

-- DropForeignKey
ALTER TABLE "contacts_boutiques" DROP CONSTRAINT "contacts_boutiques_boutique_id_fkey";

-- DropForeignKey
ALTER TABLE "ecritures_comptables" DROP CONSTRAINT "ecritures_comptables_transaction_portefeuille_id_fkey";

-- DropForeignKey
ALTER TABLE "horaires_boutiques" DROP CONSTRAINT "horaires_boutiques_boutique_id_fkey";

-- DropForeignKey
ALTER TABLE "lignes_articles_commandes" DROP CONSTRAINT "lignes_articles_commandes_article_commande_id_fkey";

-- DropForeignKey
ALTER TABLE "lignes_articles_commandes" DROP CONSTRAINT "lignes_articles_commandes_produit_id_fkey";

-- DropForeignKey
ALTER TABLE "lignes_articles_commandes" DROP CONSTRAINT "lignes_articles_commandes_variante_produit_id_fkey";

-- DropForeignKey
ALTER TABLE "litiges" DROP CONSTRAINT "litiges_commande_id_fkey";

-- DropForeignKey
ALTER TABLE "localisations_boutiques" DROP CONSTRAINT "localisations_boutiques_boutique_id_fkey";

-- DropForeignKey
ALTER TABLE "produits" DROP CONSTRAINT "produits_vendeur_id_fkey";

-- DropForeignKey
ALTER TABLE "publications" DROP CONSTRAINT "publications_vendeur_id_fkey";

-- DropForeignKey
ALTER TABLE "remboursements" DROP CONSTRAINT "remboursements_commande_id_fkey";

-- DropForeignKey
ALTER TABLE "retraits" DROP CONSTRAINT "retraits_portefeuille_id_fkey";

-- DropForeignKey
ALTER TABLE "sequestres" DROP CONSTRAINT "sequestres_commande_id_fkey";

-- DropForeignKey
ALTER TABLE "stories" DROP CONSTRAINT "stories_vendeur_id_fkey";

-- DropForeignKey
ALTER TABLE "transactions_portefeuilles" DROP CONSTRAINT "transactions_portefeuilles_portefeuille_id_fkey";

-- DropIndex
DROP INDEX "ecritures_comptables_transaction_portefeuille_id_idx";

-- DropIndex
DROP INDEX "litiges_commande_id_idx";

-- DropIndex
DROP INDEX "produits_vendeur_id_idx";

-- DropIndex
DROP INDEX "publications_vendeur_id_idx";

-- DropIndex
DROP INDEX "remboursements_commande_id_idx";

-- DropIndex
DROP INDEX "sequestres_commande_id_idx";

-- DropIndex
DROP INDEX "stories_vendeur_id_idx";

-- AlterTable
ALTER TABLE "ecritures_comptables" DROP COLUMN "transaction_portefeuille_id";

-- AlterTable
ALTER TABLE "litiges" DROP COLUMN "commande_id",
ADD COLUMN     "sous_commande_id" UUID NOT NULL;

-- AlterTable
ALTER TABLE "paiements" ADD COLUMN     "reference_externe" TEXT;

-- AlterTable
ALTER TABLE "produits" DROP COLUMN "vendeur_id",
ADD COLUMN     "boutique_id" UUID NOT NULL;

-- AlterTable
ALTER TABLE "publications" DROP COLUMN "vendeur_id",
ADD COLUMN     "boutique_id" UUID NOT NULL;

-- AlterTable
ALTER TABLE "remboursements" DROP COLUMN "commande_id",
ADD COLUMN     "sous_commande_id" UUID NOT NULL;

-- AlterTable
ALTER TABLE "sequestres" DROP COLUMN "commande_id",
ADD COLUMN     "sous_commande_id" UUID NOT NULL;

-- AlterTable
ALTER TABLE "stories" DROP COLUMN "vendeur_id",
ADD COLUMN     "boutique_id" UUID NOT NULL;

-- DropTable
DROP TABLE "_PortefeuilleToUtilisateur";

-- DropTable
DROP TABLE "articles_commandes";

-- DropTable
DROP TABLE "contacts_boutiques";

-- DropTable
DROP TABLE "horaires_boutiques";

-- DropTable
DROP TABLE "lignes_articles_commandes";

-- DropTable
DROP TABLE "localisations_boutiques";

-- DropTable
DROP TABLE "portefeuilles";

-- DropTable
DROP TABLE "retraits";

-- DropTable
DROP TABLE "transactions_portefeuilles";

-- DropEnum
DROP TYPE "JourSemaine";

-- DropEnum
DROP TYPE "MoyenRetrait";

-- DropEnum
DROP TYPE "StatutPortefeuille";

-- DropEnum
DROP TYPE "StatutRetrait";

-- DropEnum
DROP TYPE "StatutTransactionPortefeuille";

-- DropEnum
DROP TYPE "TypeContactBoutique";

-- DropEnum
DROP TYPE "TypePortefeuille";

-- DropEnum
DROP TYPE "TypeTransactionPortefeuille";

-- CreateTable
CREATE TABLE "avis" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "ligne_sous_commande_id" UUID NOT NULL,
    "note" INTEGER NOT NULL,
    "commentaire" TEXT,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "avis_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "adresses_livraison_commandes" (
    "id" UUID NOT NULL,
    "commande_id" UUID NOT NULL,
    "ville" TEXT NOT NULL,
    "quartier" TEXT,
    "lieu" TEXT NOT NULL,
    "indications" TEXT,
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "position" geography(Point,4326),

    CONSTRAINT "adresses_livraison_commandes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lignes_sous_commandes" (
    "id" UUID NOT NULL,
    "article_commande_id" UUID NOT NULL,
    "produit_id" UUID,
    "variante_produit_id" UUID,
    "produit_snapshot" JSONB NOT NULL,
    "variante_snapshot" JSONB,
    "nom_produit_snapshot" TEXT NOT NULL,
    "quantite" INTEGER NOT NULL,
    "prix_unitaire" DECIMAL(12,2) NOT NULL,

    CONSTRAINT "lignes_sous_commandes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sous_commandes" (
    "id" UUID NOT NULL,
    "commande_id" UUID NOT NULL,
    "vendeur_id" UUID NOT NULL,
    "statut" "StatutCommande" NOT NULL DEFAULT 'NOUVELLE',
    "montant_total" DECIMAL(12,2) NOT NULL,
    "devise" TEXT NOT NULL DEFAULT 'XAF',
    "sous_total" DECIMAL(12,2) NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sous_commandes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "codes_verification" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID,
    "destination" TEXT NOT NULL,
    "code_hash" TEXT NOT NULL,
    "type" "TypeCodeVerification" NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_expiration" TIMESTAMPTZ(3) NOT NULL,
    "nombre_tentatives" INTEGER NOT NULL DEFAULT 0,
    "date_utilisation" TIMESTAMPTZ(3),

    CONSTRAINT "codes_verification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reinitialisations_mots_de_passe" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "jeton_hash" TEXT NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_expiration" TIMESTAMPTZ(3) NOT NULL,
    "date_utilisation" TIMESTAMPTZ(3),

    CONSTRAINT "reinitialisations_mots_de_passe_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sessions" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "jeton_rafraichissement_hash" TEXT NOT NULL,
    "famille_jeton" TEXT NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_expiration" TIMESTAMPTZ(3) NOT NULL,
    "date_derniere_utilisation" TIMESTAMPTZ(3),
    "date_revocation" TIMESTAMPTZ(3),
    "adresse_ip_creation" TEXT,
    "appareil_id" UUID,

    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "avis_ligne_sous_commande_id_key" ON "avis"("ligne_sous_commande_id");

-- CreateIndex
CREATE INDEX "avis_utilisateur_id_idx" ON "avis"("utilisateur_id");

-- CreateIndex
CREATE UNIQUE INDEX "adresses_livraison_commandes_commande_id_key" ON "adresses_livraison_commandes"("commande_id");

-- CreateIndex
CREATE INDEX "lignes_sous_commandes_article_commande_id_idx" ON "lignes_sous_commandes"("article_commande_id");

-- CreateIndex
CREATE INDEX "lignes_sous_commandes_produit_id_idx" ON "lignes_sous_commandes"("produit_id");

-- CreateIndex
CREATE INDEX "lignes_sous_commandes_variante_produit_id_idx" ON "lignes_sous_commandes"("variante_produit_id");

-- CreateIndex
CREATE INDEX "sous_commandes_commande_id_idx" ON "sous_commandes"("commande_id");

-- CreateIndex
CREATE INDEX "sous_commandes_vendeur_id_idx" ON "sous_commandes"("vendeur_id");

-- CreateIndex
CREATE INDEX "sous_commandes_statut_idx" ON "sous_commandes"("statut");

-- CreateIndex
CREATE INDEX "codes_verification_utilisateur_id_idx" ON "codes_verification"("utilisateur_id");

-- CreateIndex
CREATE INDEX "codes_verification_destination_type_idx" ON "codes_verification"("destination", "type");

-- CreateIndex
CREATE INDEX "codes_verification_date_expiration_idx" ON "codes_verification"("date_expiration");

-- CreateIndex
CREATE INDEX "reinitialisations_mots_de_passe_utilisateur_id_idx" ON "reinitialisations_mots_de_passe"("utilisateur_id");

-- CreateIndex
CREATE INDEX "reinitialisations_mots_de_passe_date_expiration_idx" ON "reinitialisations_mots_de_passe"("date_expiration");

-- CreateIndex
CREATE INDEX "sessions_utilisateur_id_idx" ON "sessions"("utilisateur_id");

-- CreateIndex
CREATE INDEX "sessions_famille_jeton_idx" ON "sessions"("famille_jeton");

-- CreateIndex
CREATE INDEX "sessions_date_expiration_idx" ON "sessions"("date_expiration");

-- CreateIndex
CREATE INDEX "litiges_sous_commande_id_idx" ON "litiges"("sous_commande_id");

-- CreateIndex
CREATE UNIQUE INDEX "paiements_reference_externe_key" ON "paiements"("reference_externe");

-- CreateIndex
CREATE INDEX "produits_boutique_id_idx" ON "produits"("boutique_id");

-- CreateIndex
CREATE INDEX "publications_boutique_id_idx" ON "publications"("boutique_id");

-- CreateIndex
CREATE INDEX "remboursements_sous_commande_id_idx" ON "remboursements"("sous_commande_id");

-- CreateIndex
CREATE INDEX "sequestres_sous_commande_id_idx" ON "sequestres"("sous_commande_id");

-- CreateIndex
CREATE INDEX "stories_boutique_id_idx" ON "stories"("boutique_id");

-- AddForeignKey
ALTER TABLE "avis" ADD CONSTRAINT "avis_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "avis" ADD CONSTRAINT "avis_ligne_sous_commande_id_fkey" FOREIGN KEY ("ligne_sous_commande_id") REFERENCES "lignes_sous_commandes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "produits" ADD CONSTRAINT "produits_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "adresses_livraison_commandes" ADD CONSTRAINT "adresses_livraison_commandes_commande_id_fkey" FOREIGN KEY ("commande_id") REFERENCES "commandes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lignes_sous_commandes" ADD CONSTRAINT "lignes_sous_commandes_article_commande_id_fkey" FOREIGN KEY ("article_commande_id") REFERENCES "sous_commandes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lignes_sous_commandes" ADD CONSTRAINT "lignes_sous_commandes_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lignes_sous_commandes" ADD CONSTRAINT "lignes_sous_commandes_variante_produit_id_fkey" FOREIGN KEY ("variante_produit_id") REFERENCES "variantes_produits"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sous_commandes" ADD CONSTRAINT "sous_commandes_commande_id_fkey" FOREIGN KEY ("commande_id") REFERENCES "commandes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sous_commandes" ADD CONSTRAINT "sous_commandes_vendeur_id_fkey" FOREIGN KEY ("vendeur_id") REFERENCES "vendeurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publications" ADD CONSTRAINT "publications_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stories" ADD CONSTRAINT "stories_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "adresses" ADD CONSTRAINT "adresses_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "codes_verification" ADD CONSTRAINT "codes_verification_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reinitialisations_mots_de_passe" ADD CONSTRAINT "reinitialisations_mots_de_passe_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_appareil_id_fkey" FOREIGN KEY ("appareil_id") REFERENCES "appareils"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "litiges" ADD CONSTRAINT "litiges_sous_commande_id_fkey" FOREIGN KEY ("sous_commande_id") REFERENCES "sous_commandes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "remboursements" ADD CONSTRAINT "remboursements_sous_commande_id_fkey" FOREIGN KEY ("sous_commande_id") REFERENCES "sous_commandes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sequestres" ADD CONSTRAINT "sequestres_sous_commande_id_fkey" FOREIGN KEY ("sous_commande_id") REFERENCES "sous_commandes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

