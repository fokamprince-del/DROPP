-- AlterEnum
ALTER TYPE "TypeEvenementSecurite" ADD VALUE 'COMPTE_SUPPRIME';

-- AlterTable
ALTER TABLE "publications" ADD COLUMN     "nombre_vues" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "utilisateurs" ADD COLUMN     "pseudo" TEXT;

-- CreateTable
CREATE TABLE "vues_stories" (
    "story_id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "date_vue" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vues_stories_pkey" PRIMARY KEY ("story_id","utilisateur_id")
);

-- CreateIndex
CREATE INDEX "vues_stories_utilisateur_id_idx" ON "vues_stories"("utilisateur_id");

-- CreateIndex
CREATE UNIQUE INDEX "medias_cle_stockage_key" ON "medias"("cle_stockage");

-- CreateIndex
CREATE UNIQUE INDEX "utilisateurs_pseudo_key" ON "utilisateurs"("pseudo");

-- AddForeignKey
ALTER TABLE "vues_stories" ADD CONSTRAINT "vues_stories_story_id_fkey" FOREIGN KEY ("story_id") REFERENCES "stories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vues_stories" ADD CONSTRAINT "vues_stories_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Contraintes CHECK
ALTER TABLE "utilisateurs" ADD CONSTRAINT "utilisateurs_pseudo_format"
  CHECK (pseudo IS NULL OR pseudo ~ '^[a-z0-9_.]{3,30}$');

ALTER TABLE "publications" ADD CONSTRAINT "publications_nombre_vues_positif"
  CHECK (nombre_vues >= 0);

ALTER TABLE "avis" ADD CONSTRAINT "avis_note_entre_1_et_5"
  CHECK (note BETWEEN 1 AND 5);
