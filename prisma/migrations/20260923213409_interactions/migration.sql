-- AlterTable
ALTER TABLE "commentaires" ADD COLUMN     "est_createur" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "parent_id" UUID;

-- CreateTable
CREATE TABLE "aimes_commentaires" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "commentaire_id" UUID NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "aimes_commentaires_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "partages" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "publication_id" UUID NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "partages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "aimes_commentaires_commentaire_id_idx" ON "aimes_commentaires"("commentaire_id");

-- CreateIndex
CREATE UNIQUE INDEX "aimes_commentaires_utilisateur_id_commentaire_id_key" ON "aimes_commentaires"("utilisateur_id", "commentaire_id");

-- CreateIndex
CREATE INDEX "partages_publication_id_idx" ON "partages"("publication_id");

-- CreateIndex
CREATE UNIQUE INDEX "partages_utilisateur_id_publication_id_key" ON "partages"("utilisateur_id", "publication_id");

-- AddForeignKey
ALTER TABLE "aimes_commentaires" ADD CONSTRAINT "aimes_commentaires_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "aimes_commentaires" ADD CONSTRAINT "aimes_commentaires_commentaire_id_fkey" FOREIGN KEY ("commentaire_id") REFERENCES "commentaires"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commentaires" ADD CONSTRAINT "commentaires_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "commentaires"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "partages" ADD CONSTRAINT "partages_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "partages" ADD CONSTRAINT "partages_publication_id_fkey" FOREIGN KEY ("publication_id") REFERENCES "publications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Pas de self-follow
ALTER TABLE abonnements
  ADD CONSTRAINT chk_pas_de_self_follow
  CHECK (utilisateur_id <> vendeur_id);

-- Un commentaire ne peut répondre qu'à un commentaire racine (pas d'imbrication infinie)
-- PostgreSQL interdit les sous-requêtes dans CHECK, donc on utilise un trigger.
CREATE OR REPLACE FUNCTION verifier_profondeur_commentaire()
RETURNS trigger AS $$
BEGIN
  IF NEW.parent_id IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM commentaires
      WHERE id = NEW.parent_id
        AND parent_id IS NOT NULL
    ) THEN
      RAISE EXCEPTION 'Un commentaire ne peut répondre qu''à un commentaire racine.'
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profondeur_commentaire
  BEFORE INSERT OR UPDATE OF parent_id ON commentaires
  FOR EACH ROW EXECUTE FUNCTION verifier_profondeur_commentaire();