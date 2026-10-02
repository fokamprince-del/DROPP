-- AlterEnum
ALTER TYPE "TypeNotification" ADD VALUE 'SOCIAL';

-- AlterTable
ALTER TABLE "boutiques" ADD COLUMN     "banniere_cle" TEXT,
ADD COLUMN     "logo_cle" TEXT;

-- AlterTable
ALTER TABLE "utilisateurs" ADD COLUMN     "photo_profil_cle" TEXT;

-- AlterTable
ALTER TABLE "signalements" ADD COLUMN     "boutique_id" UUID,
ADD COLUMN     "message_id" UUID;

-- AlterTable
ALTER TABLE "notifications" ADD COLUMN     "donnees" JSONB;

-- CreateTable
CREATE TABLE "blocages" (
    "bloqueur_id" UUID NOT NULL,
    "bloque_id" UUID NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "blocages_pkey" PRIMARY KEY ("bloqueur_id","bloque_id")
);

-- CreateIndex
CREATE INDEX "blocages_bloque_id_idx" ON "blocages"("bloque_id");

-- CreateIndex
CREATE INDEX "signalements_boutique_id_idx" ON "signalements"("boutique_id");

-- CreateIndex
CREATE INDEX "signalements_message_id_idx" ON "signalements"("message_id");

-- AddForeignKey
ALTER TABLE "blocages" ADD CONSTRAINT "blocages_bloqueur_id_fkey" FOREIGN KEY ("bloqueur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "blocages" ADD CONSTRAINT "blocages_bloque_id_fkey" FOREIGN KEY ("bloque_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signalements" ADD CONSTRAINT "signalements_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signalements" ADD CONSTRAINT "signalements_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Contraintes CHECK
ALTER TABLE "blocages" ADD CONSTRAINT "blocages_pas_soi_meme"
  CHECK (bloqueur_id <> bloque_id);

-- Un signalement vise au plus une cible (0 si la cible a été supprimée).
ALTER TABLE "signalements" ADD CONSTRAINT "signalements_une_seule_cible"
  CHECK (num_nonnulls(publication_id, commentaire_id, produit_id, boutique_id, message_id) <= 1);

ALTER TABLE "signalements" ADD CONSTRAINT "signalements_motif_non_vide"
  CHECK (length(motif) > 0);

-- Liste des conversations d'un utilisateur triée par activité.
CREATE INDEX "messages_conversation_id_date_creation_idx"
  ON "messages"("conversation_id", "date_creation" DESC);
