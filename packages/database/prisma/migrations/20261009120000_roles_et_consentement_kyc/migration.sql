-- Rôles d'administration : référencés par le code (@Admin(...)) et par
-- seed-admin. Idempotent : sans effet si les rôles existent déjà.
INSERT INTO "roles" ("id", "nom", "description") VALUES
  (gen_random_uuid(), 'SUPER_ADMIN', 'Accès complet au back-office, gestion des rôles.'),
  (gen_random_uuid(), 'MODERATEUR', 'Modération des contenus, signalements, KYC et comptes.'),
  (gen_random_uuid(), 'GESTIONNAIRE_FINANCIER', 'Suivi des paiements, séquestres et remboursements.')
ON CONFLICT ("nom") DO NOTHING;

-- KYC : date à laquelle le vendeur a accepté le traitement de ses pièces
-- d'identité (dont la vérification faciale par un prestataire externe).
ALTER TABLE "dossiers_kyc" ADD COLUMN "consentement_le" TIMESTAMPTZ(3);
