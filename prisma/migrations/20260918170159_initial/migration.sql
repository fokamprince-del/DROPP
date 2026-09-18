-- CreateEnum
CREATE TYPE "StatutCompte" AS ENUM ('ACTIF', 'SUSPENDU_TEMP', 'SUSPENDU_DEF', 'SUPPRIME');

-- CreateEnum
CREATE TYPE "StatutVendeur" AS ENUM ('EN_ATTENTE_VALIDATION', 'ACTIF', 'SUSPENDU');

-- CreateEnum
CREATE TYPE "TypeAdresse" AS ENUM ('LIVRAISON', 'FACTURATION', 'AUTRE');

-- CreateEnum
CREATE TYPE "JourSemaine" AS ENUM ('LUNDI', 'MARDI', 'MERCREDI', 'JEUDI', 'VENDREDI', 'SAMEDI', 'DIMANCHE');

-- CreateEnum
CREATE TYPE "TypeContactBoutique" AS ENUM ('TELEPHONE', 'WHATSAPP', 'EMAIL', 'AUTRE');

-- CreateEnum
CREATE TYPE "StatutBoutique" AS ENUM ('EN_ATTENTE', 'ACTIVE', 'SUSPENDUE');

-- CreateEnum
CREATE TYPE "StatutCategorie" AS ENUM ('ACTIVE', 'INACTIVE');

-- CreateEnum
CREATE TYPE "StatutProduit" AS ENUM ('BROUILLON', 'PROCESSING', 'PUBLIE', 'REJETE', 'ARCHIVE');

-- CreateEnum
CREATE TYPE "TypeMedia" AS ENUM ('VIDEO', 'IMAGE');

-- CreateEnum
CREATE TYPE "StatutTraitementMedia" AS ENUM ('PROCESSING', 'PRET', 'ECHEC');

-- CreateEnum
CREATE TYPE "TypePublication" AS ENUM ('VIDEO', 'IMAGE', 'CARROUSEL');

-- CreateEnum
CREATE TYPE "VisibiliteContenu" AS ENUM ('PUBLIC', 'ABONNES');

-- CreateEnum
CREATE TYPE "StatutPublication" AS ENUM ('PROCESSING', 'PUBLIEE', 'REJETEE', 'SUPPRIMEE');

-- CreateEnum
CREATE TYPE "StatutCommentaire" AS ENUM ('VISIBLE', 'MASQUE_MODERATION', 'SUPPRIME');

-- CreateEnum
CREATE TYPE "StatutAbonnement" AS ENUM ('ACTIF', 'MUET', 'BLOQUE');

-- CreateEnum
CREATE TYPE "TypeConversation" AS ENUM ('DIRECTE', 'GROUPE');

-- CreateEnum
CREATE TYPE "StatutConversation" AS ENUM ('ACTIVE', 'ARCHIVEE', 'FERMEE');

-- CreateEnum
CREATE TYPE "TypeMessage" AS ENUM ('TEXTE', 'IMAGE', 'VIDEO', 'FICHIER', 'LOCALISATION');

-- CreateEnum
CREATE TYPE "StatutMessage" AS ENUM ('ENVOYE', 'LU');

-- CreateEnum
CREATE TYPE "StatutKyc" AS ENUM ('EN_ATTENTE', 'VALIDE', 'REJETE');

-- CreateEnum
CREATE TYPE "TypeDocumentKyc" AS ENUM ('CNI_RECTO', 'CNI_VERSO', 'PHOTO_FACIALE');

-- CreateEnum
CREATE TYPE "StatutDocumentKyc" AS ENUM ('SOUMIS', 'VALIDE', 'REJETE');

-- CreateEnum
CREATE TYPE "TypeVerificationKyc" AS ENUM ('FACIALE', 'MANUELLE');

-- CreateEnum
CREATE TYPE "StatutVerificationKyc" AS ENUM ('EN_ATTENTE', 'VALIDE', 'REJETE', 'ERREUR');

-- CreateEnum
CREATE TYPE "StatutPanier" AS ENUM ('ACTIF', 'ABANDONNE', 'CONVERTI');

-- CreateEnum
CREATE TYPE "StatutPassageCommande" AS ENUM ('EN_COURS', 'COMPLETE', 'EXPIRE', 'ANNULE');

-- CreateEnum
CREATE TYPE "StatutCommande" AS ENUM ('EN_ATTENTE_PAIEMENT', 'NOUVELLE', 'EN_COURS', 'EXPEDIEE', 'LIVREE', 'ANNULEE', 'EN_LITIGE');

-- CreateEnum
CREATE TYPE "MoyenPaiement" AS ENUM ('MOBILE_MONEY_MTN', 'MOBILE_MONEY_ORANGE', 'PORTEFEUILLE');

-- CreateEnum
CREATE TYPE "StatutPaiement" AS ENUM ('EN_ATTENTE', 'SUCCES', 'ECHOUE', 'ANNULE', 'REMBOURSE');

-- CreateEnum
CREATE TYPE "FournisseurPaiement" AS ENUM ('CAMPAY', 'MONETBIL');

-- CreateEnum
CREATE TYPE "StatutSequestre" AS ENUM ('BLOQUE', 'LIBERE', 'REMBOURSE');

-- CreateEnum
CREATE TYPE "TypeRemboursement" AS ENUM ('TOTAL', 'PARTIEL');

-- CreateEnum
CREATE TYPE "StatutRemboursement" AS ENUM ('EN_ATTENTE', 'EFFECTUE', 'ECHOUE');

-- CreateEnum
CREATE TYPE "TypePortefeuille" AS ENUM ('CLIENT', 'VENDEUR', 'DROPP');

-- CreateEnum
CREATE TYPE "StatutPortefeuille" AS ENUM ('ACTIF', 'BLOQUE', 'FERME');

-- CreateEnum
CREATE TYPE "TypeTransactionPortefeuille" AS ENUM ('DEPOT', 'ACHAT', 'REMBOURSEMENT', 'GAIN_PARRAINAGE', 'RETRAIT', 'COMMISSION');

-- CreateEnum
CREATE TYPE "StatutTransactionPortefeuille" AS ENUM ('EN_ATTENTE', 'CONFIRMEE', 'ECHOUEE', 'ANNULEE');

-- CreateEnum
CREATE TYPE "MoyenRetrait" AS ENUM ('MTN', 'ORANGE');

-- CreateEnum
CREATE TYPE "StatutRetrait" AS ENUM ('EN_COURS', 'EFFECTUE', 'REJETE');

-- CreateEnum
CREATE TYPE "TypeCompteComptable" AS ENUM ('ACTIF', 'PASSIF', 'CHARGE', 'PRODUIT');

-- CreateEnum
CREATE TYPE "StatutJournalComptable" AS ENUM ('BROUILLON', 'VALIDE', 'ANNULE');

-- CreateEnum
CREATE TYPE "StatutSignalement" AS ENUM ('OUVERT', 'EN_COURS', 'TRAITE', 'REJETE');

-- CreateEnum
CREATE TYPE "PrioriteSignalement" AS ENUM ('BASSE', 'NORMALE', 'HAUTE', 'CRITIQUE');

-- CreateEnum
CREATE TYPE "StatutModeration" AS ENUM ('OUVERT', 'EN_COURS', 'CLOTURE');

-- CreateEnum
CREATE TYPE "ActionModeration" AS ENUM ('AUCUNE', 'MASQUER', 'SUPPRIMER', 'SUSPENDRE', 'REJETER');

-- CreateEnum
CREATE TYPE "StatutLitige" AS ENUM ('OUVERT', 'EN_ARBITRAGE', 'RESOLU');

-- CreateEnum
CREATE TYPE "TypePreuveLitige" AS ENUM ('PHOTO', 'VIDEO', 'DOCUMENT');

-- CreateEnum
CREATE TYPE "TypeNotification" AS ENUM ('COMMANDE', 'PAIEMENT', 'MESSAGE', 'PROMOTION', 'SYSTEME', 'SECURITE');

-- CreateEnum
CREATE TYPE "PlateformeAppareil" AS ENUM ('ANDROID', 'IOS');

-- CreateTable
CREATE TABLE "journaux_audit" (
    "id" UUID NOT NULL,
    "administrateur_id" UUID,
    "action" TEXT NOT NULL,
    "resource_type" TEXT NOT NULL,
    "resource_id" TEXT NOT NULL,
    "adresse_ip" TEXT,
    "details" JSONB,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "journaux_audit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "boutiques" (
    "id" UUID NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "biographie" TEXT,
    "statut" "StatutBoutique" NOT NULL DEFAULT 'EN_ATTENTE',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "boutiques_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "localisations_boutiques" (
    "id" UUID NOT NULL,
    "boutique_id" UUID NOT NULL,
    "adresse" TEXT NOT NULL,
    "ville" TEXT NOT NULL,
    "region" TEXT,
    "pays" TEXT NOT NULL,
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "position" geography(Point,4326),
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "localisations_boutiques_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "horaires_boutiques" (
    "id" UUID NOT NULL,
    "boutique_id" UUID NOT NULL,
    "jour_semaine" "JourSemaine" NOT NULL,
    "heure_ouverture" TIME(0),
    "heure_fermeture" TIME(0),
    "ferme" BOOLEAN NOT NULL DEFAULT false,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "horaires_boutiques_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "contacts_boutiques" (
    "id" UUID NOT NULL,
    "boutique_id" UUID NOT NULL,
    "type" "TypeContactBoutique" NOT NULL,
    "valeur" TEXT NOT NULL,
    "est_principal" BOOLEAN NOT NULL DEFAULT false,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "contacts_boutiques_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "categories" (
    "id" UUID NOT NULL,
    "parent_id" UUID,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "statut" "StatutCategorie" NOT NULL DEFAULT 'ACTIVE',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "produits" (
    "id" UUID NOT NULL,
    "vendeur_id" UUID NOT NULL,
    "categorie_id" UUID NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "statut" "StatutProduit" NOT NULL DEFAULT 'BROUILLON',
    "prix_base" DECIMAL(12,2) NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "produits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "variantes_produits" (
    "id" UUID NOT NULL,
    "produit_id" UUID NOT NULL,
    "sku" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "attributs" JSONB NOT NULL,
    "prix" DECIMAL(12,2),
    "stock_disponible" INTEGER NOT NULL DEFAULT 0,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "variantes_produits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medias" (
    "id" UUID NOT NULL,
    "type_media" "TypeMedia" NOT NULL,
    "cle_stockage" TEXT NOT NULL,
    "type_mime" TEXT NOT NULL,
    "taille" BIGINT NOT NULL,
    "largeur" INTEGER,
    "hauteur" INTEGER,
    "duree" INTEGER,
    "statut_traitement" "StatutTraitementMedia" NOT NULL DEFAULT 'PROCESSING',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "medias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medias_produits" (
    "id" UUID NOT NULL,
    "produit_id" UUID NOT NULL,
    "media_id" UUID NOT NULL,
    "ordre" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "medias_produits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "passages_commandes" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "panier_id" UUID NOT NULL,
    "statut" "StatutPassageCommande" NOT NULL DEFAULT 'EN_COURS',
    "montant_total" DECIMAL(12,2) NOT NULL,
    "devise" TEXT NOT NULL DEFAULT 'XAF',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "passages_commandes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commandes" (
    "id" UUID NOT NULL,
    "passage_commande_id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "statut" "StatutCommande" NOT NULL DEFAULT 'EN_ATTENTE_PAIEMENT',
    "montant_total" DECIMAL(12,2) NOT NULL,
    "devise" TEXT NOT NULL DEFAULT 'XAF',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "commandes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "articles_commandes" (
    "id" UUID NOT NULL,
    "commande_id" UUID NOT NULL,
    "vendeur_id" UUID NOT NULL,
    "statut" "StatutCommande" NOT NULL DEFAULT 'NOUVELLE',
    "montant_total" DECIMAL(12,2) NOT NULL,
    "devise" TEXT NOT NULL DEFAULT 'XAF',
    "sous_total" DECIMAL(12,2) NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "articles_commandes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lignes_articles_commandes" (
    "id" UUID NOT NULL,
    "article_commande_id" UUID NOT NULL,
    "produit_id" UUID,
    "variante_produit_id" UUID,
    "produit_snapshot" JSONB NOT NULL,
    "variante_snapshot" JSONB,
    "nom_produit_snapshot" TEXT NOT NULL,
    "quantite" INTEGER NOT NULL,
    "prix_unitaire" DECIMAL(12,2) NOT NULL,

    CONSTRAINT "lignes_articles_commandes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "aimes" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "publication_id" UUID NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "aimes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commentaires" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "publication_id" UUID NOT NULL,
    "contenu" TEXT NOT NULL,
    "statut" "StatutCommentaire" NOT NULL DEFAULT 'VISIBLE',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "commentaires_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "favoris_publications" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "publication_id" UUID NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "favoris_publications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "favoris_produits" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "produit_id" UUID NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "favoris_produits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "abonnements" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "vendeur_id" UUID NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "statut" "StatutAbonnement" NOT NULL DEFAULT 'ACTIF',

    CONSTRAINT "abonnements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dossiers_kyc" (
    "id" UUID NOT NULL,
    "vendeur_id" UUID NOT NULL,
    "statut" "StatutKyc" NOT NULL DEFAULT 'EN_ATTENTE',
    "date_soumission" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_validation" TIMESTAMPTZ(3),
    "date_rejet" TIMESTAMPTZ(3),
    "motif_rejet" TEXT,

    CONSTRAINT "dossiers_kyc_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "documents_kyc" (
    "id" UUID NOT NULL,
    "dossier_kyc_id" UUID NOT NULL,
    "type_document" "TypeDocumentKyc" NOT NULL,
    "cle_stockage" TEXT NOT NULL,
    "nom_original" TEXT NOT NULL,
    "type_mime" TEXT NOT NULL,
    "taille" BIGINT NOT NULL,
    "statut" "StatutDocumentKyc" NOT NULL DEFAULT 'SOUMIS',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "documents_kyc_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "verifications_kyc" (
    "id" UUID NOT NULL,
    "dossier_kyc_id" UUID NOT NULL,
    "type_verification" "TypeVerificationKyc" NOT NULL,
    "statut" "StatutVerificationKyc" NOT NULL DEFAULT 'EN_ATTENTE',
    "commentaire" TEXT,
    "date_verification" TIMESTAMPTZ(3),
    "score_matching" DECIMAL(5,4),
    "seuil_decision" DECIMAL(5,4),

    CONSTRAINT "verifications_kyc_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "revues_kyc" (
    "id" UUID NOT NULL,
    "dossier_kyc_id" UUID NOT NULL,
    "administrateur_id" UUID NOT NULL,
    "statut" "StatutKyc" NOT NULL,
    "commentaire" TEXT,
    "date_revue" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "revues_kyc_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "conversations" (
    "id" UUID NOT NULL,
    "type" "TypeConversation" NOT NULL,
    "statut" "StatutConversation" NOT NULL DEFAULT 'ACTIVE',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_derniere_activite" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "participants_conversations" (
    "conversation_id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "date_entree" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "participants_conversations_pkey" PRIMARY KEY ("conversation_id","utilisateur_id")
);

-- CreateTable
CREATE TABLE "messages" (
    "id" UUID NOT NULL,
    "conversation_id" UUID NOT NULL,
    "expediteur_id" UUID NOT NULL,
    "contenu" TEXT,
    "type" "TypeMessage" NOT NULL,
    "statut" "StatutMessage" NOT NULL DEFAULT 'ENVOYE',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pieces_jointes_messages" (
    "id" UUID NOT NULL,
    "message_id" UUID NOT NULL,
    "media_id" UUID NOT NULL,
    "type" "TypeMedia" NOT NULL,

    CONSTRAINT "pieces_jointes_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "signalements" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "publication_id" UUID,
    "commentaire_id" UUID,
    "produit_id" UUID,
    "motif" TEXT NOT NULL,
    "description" TEXT,
    "statut" "StatutSignalement" NOT NULL DEFAULT 'OUVERT',
    "priorite" "PrioriteSignalement" NOT NULL DEFAULT 'NORMALE',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "signalements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dossiers_moderation" (
    "id" UUID NOT NULL,
    "administrateur_id" UUID,
    "statut" "StatutModeration" NOT NULL DEFAULT 'OUVERT',
    "action" "ActionModeration" NOT NULL DEFAULT 'AUCUNE',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_cloture" TIMESTAMPTZ(3),

    CONSTRAINT "dossiers_moderation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "litiges" (
    "id" UUID NOT NULL,
    "commande_id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "motif" TEXT NOT NULL,
    "statut" "StatutLitige" NOT NULL DEFAULT 'OUVERT',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_resolution" TIMESTAMPTZ(3),

    CONSTRAINT "litiges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "preuves_litiges" (
    "id" UUID NOT NULL,
    "litige_id" UUID NOT NULL,
    "media_id" UUID NOT NULL,
    "type" "TypePreuveLitige" NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "preuves_litiges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "type" "TypeNotification" NOT NULL,
    "titre" TEXT NOT NULL,
    "contenu" TEXT NOT NULL,
    "est_lu" BOOLEAN NOT NULL DEFAULT false,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_lecture" TIMESTAMPTZ(3),

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "preferences_notifications" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "type" "TypeNotification" NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "preferences_notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "appareils" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "token_fcm" TEXT NOT NULL,
    "plateforme" "PlateformeAppareil" NOT NULL,
    "modele" TEXT,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "derniere_utilisation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "appareils_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "paiements" (
    "id" UUID NOT NULL,
    "passage_commande_id" UUID NOT NULL,
    "montant" DECIMAL(12,2) NOT NULL,
    "devise" TEXT NOT NULL DEFAULT 'XAF',
    "moyen_paiement" "MoyenPaiement" NOT NULL,
    "statut" "StatutPaiement" NOT NULL DEFAULT 'EN_ATTENTE',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_confirmation" TIMESTAMPTZ(3),

    CONSTRAINT "paiements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tentatives_paiements" (
    "id" UUID NOT NULL,
    "paiement_id" UUID NOT NULL,
    "fournisseur" "FournisseurPaiement" NOT NULL,
    "reference_fournisseur" TEXT NOT NULL,
    "montant" DECIMAL(12,2) NOT NULL,
    "statut" "StatutPaiement" NOT NULL DEFAULT 'EN_ATTENTE',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_confirmation" TIMESTAMPTZ(3),

    CONSTRAINT "tentatives_paiements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "allocations_paiements" (
    "id" UUID NOT NULL,
    "paiement_id" UUID NOT NULL,
    "commande_id" UUID NOT NULL,
    "montant" DECIMAL(12,2) NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "allocations_paiements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sequestres" (
    "id" UUID NOT NULL,
    "commande_id" UUID NOT NULL,
    "montant" DECIMAL(12,2) NOT NULL,
    "devise" TEXT NOT NULL DEFAULT 'XAF',
    "statut" "StatutSequestre" NOT NULL DEFAULT 'BLOQUE',
    "motif" TEXT,
    "date_blocage" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_liberation_prevue" TIMESTAMPTZ(3),
    "date_liberation" TIMESTAMPTZ(3),

    CONSTRAINT "sequestres_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "remboursements" (
    "id" UUID NOT NULL,
    "commande_id" UUID NOT NULL,
    "montant" DECIMAL(12,2) NOT NULL,
    "type" "TypeRemboursement" NOT NULL,
    "statut" "StatutRemboursement" NOT NULL DEFAULT 'EN_ATTENTE',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_execution" TIMESTAMPTZ(3),

    CONSTRAINT "remboursements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "paniers" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "statut" "StatutPanier" NOT NULL DEFAULT 'ACTIF',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "paniers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "articles_paniers" (
    "id" UUID NOT NULL,
    "panier_id" UUID NOT NULL,
    "variante_produit_id" UUID NOT NULL,
    "quantite" INTEGER NOT NULL,
    "prix_unitaire" DECIMAL(12,2) NOT NULL,
    "date_ajout" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "articles_paniers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "portefeuilles" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "type" "TypePortefeuille" NOT NULL,
    "solde" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "solde_disponible" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "devise" TEXT NOT NULL DEFAULT 'XAF',
    "statut" "StatutPortefeuille" NOT NULL DEFAULT 'ACTIF',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "portefeuilles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transactions_portefeuilles" (
    "id" UUID NOT NULL,
    "portefeuille_id" UUID NOT NULL,
    "type" "TypeTransactionPortefeuille" NOT NULL,
    "montant" DECIMAL(12,2) NOT NULL,
    "devise" TEXT NOT NULL DEFAULT 'XAF',
    "statut" "StatutTransactionPortefeuille" NOT NULL DEFAULT 'EN_ATTENTE',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "description" TEXT,

    CONSTRAINT "transactions_portefeuilles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "retraits" (
    "id" UUID NOT NULL,
    "portefeuille_id" UUID NOT NULL,
    "montant" DECIMAL(12,2) NOT NULL,
    "moyen_retrait" "MoyenRetrait" NOT NULL,
    "numero_destination" TEXT NOT NULL,
    "statut" "StatutRetrait" NOT NULL DEFAULT 'EN_COURS',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_execution" TIMESTAMPTZ(3),

    CONSTRAINT "retraits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "comptes_comptables" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "libelle" TEXT NOT NULL,
    "type" "TypeCompteComptable" NOT NULL,

    CONSTRAINT "comptes_comptables_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "journaux_comptables" (
    "id" UUID NOT NULL,
    "date" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "type_operation" TEXT NOT NULL,
    "description" TEXT,
    "statut" "StatutJournalComptable" NOT NULL DEFAULT 'BROUILLON',

    CONSTRAINT "journaux_comptables_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecritures_comptables" (
    "id" UUID NOT NULL,
    "journal_id" UUID NOT NULL,
    "compte_id" UUID NOT NULL,
    "paiement_id" UUID,
    "transaction_portefeuille_id" UUID,
    "debit" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "credit" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "description" TEXT,

    CONSTRAINT "ecritures_comptables_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "publications" (
    "id" UUID NOT NULL,
    "vendeur_id" UUID NOT NULL,
    "contenu" TEXT,
    "type" "TypePublication" NOT NULL,
    "visibilite" "VisibiliteContenu" NOT NULL DEFAULT 'PUBLIC',
    "statut" "StatutPublication" NOT NULL DEFAULT 'PROCESSING',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_modification" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "publications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medias_publications" (
    "id" UUID NOT NULL,
    "publication_id" UUID NOT NULL,
    "media_id" UUID NOT NULL,
    "ordre" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "medias_publications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "publications_produits" (
    "id" UUID NOT NULL,
    "publication_id" UUID NOT NULL,
    "produit_id" UUID NOT NULL,
    "ordre" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "publications_produits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stories" (
    "id" UUID NOT NULL,
    "vendeur_id" UUID NOT NULL,
    "media_id" UUID NOT NULL,
    "ordre_creation" INTEGER NOT NULL DEFAULT 0,
    "visibilite" "VisibiliteContenu" NOT NULL DEFAULT 'PUBLIC',
    "statut" "StatutPublication" NOT NULL DEFAULT 'PROCESSING',
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_expiration" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "stories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "utilisateurs" (
    "id" UUID NOT NULL,
    "nom" TEXT NOT NULL,
    "prenom" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "telephone" TEXT NOT NULL,
    "mot_de_passe_hash" TEXT NOT NULL,
    "photo_profil_url" TEXT,
    "date_inscription" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "statut_compte" "StatutCompte" NOT NULL DEFAULT 'ACTIF',
    "derniere_connexion" TIMESTAMPTZ(3),
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "utilisateurs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "clients" (
    "id" UUID NOT NULL,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "statut" "StatutCompte" NOT NULL DEFAULT 'ACTIF',

    CONSTRAINT "clients_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vendeurs" (
    "id" UUID NOT NULL,
    "date_debut" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "statut_vendeur" "StatutVendeur" NOT NULL DEFAULT 'EN_ATTENTE_VALIDATION',
    "commission_personnalisee" DECIMAL(12,2),
    "biographie" TEXT,

    CONSTRAINT "vendeurs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roles" (
    "id" UUID NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "utilisateur_roles" (
    "utilisateur_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,
    "date_attribution" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "utilisateur_roles_pkey" PRIMARY KEY ("utilisateur_id","role_id")
);

-- CreateTable
CREATE TABLE "adresses" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "type" "TypeAdresse" NOT NULL,
    "ligne1" TEXT NOT NULL,
    "ligne2" TEXT,
    "ville" TEXT NOT NULL,
    "region" TEXT,
    "pays" TEXT NOT NULL,
    "code_postal" TEXT,
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "est_principale" BOOLEAN NOT NULL DEFAULT false,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "adresses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "_PortefeuilleToUtilisateur" (
    "A" UUID NOT NULL,
    "B" UUID NOT NULL,

    CONSTRAINT "_PortefeuilleToUtilisateur_AB_pkey" PRIMARY KEY ("A","B")
);

-- CreateIndex
CREATE INDEX "journaux_audit_administrateur_id_idx" ON "journaux_audit"("administrateur_id");

-- CreateIndex
CREATE INDEX "journaux_audit_resource_type_resource_id_idx" ON "journaux_audit"("resource_type", "resource_id");

-- CreateIndex
CREATE INDEX "journaux_audit_date_creation_idx" ON "journaux_audit"("date_creation");

-- CreateIndex
CREATE INDEX "boutiques_statut_idx" ON "boutiques"("statut");

-- CreateIndex
CREATE INDEX "localisations_boutiques_boutique_id_idx" ON "localisations_boutiques"("boutique_id");

-- CreateIndex
CREATE UNIQUE INDEX "horaires_boutiques_boutique_id_jour_semaine_key" ON "horaires_boutiques"("boutique_id", "jour_semaine");

-- CreateIndex
CREATE INDEX "contacts_boutiques_boutique_id_idx" ON "contacts_boutiques"("boutique_id");

-- CreateIndex
CREATE INDEX "categories_parent_id_idx" ON "categories"("parent_id");

-- CreateIndex
CREATE INDEX "categories_statut_idx" ON "categories"("statut");

-- CreateIndex
CREATE INDEX "produits_vendeur_id_idx" ON "produits"("vendeur_id");

-- CreateIndex
CREATE INDEX "produits_categorie_id_idx" ON "produits"("categorie_id");

-- CreateIndex
CREATE INDEX "produits_statut_idx" ON "produits"("statut");

-- CreateIndex
CREATE INDEX "produits_date_creation_idx" ON "produits"("date_creation");

-- CreateIndex
CREATE UNIQUE INDEX "variantes_produits_sku_key" ON "variantes_produits"("sku");

-- CreateIndex
CREATE INDEX "variantes_produits_produit_id_idx" ON "variantes_produits"("produit_id");

-- CreateIndex
CREATE INDEX "medias_statut_traitement_idx" ON "medias"("statut_traitement");

-- CreateIndex
CREATE INDEX "medias_date_creation_idx" ON "medias"("date_creation");

-- CreateIndex
CREATE INDEX "medias_produits_media_id_idx" ON "medias_produits"("media_id");

-- CreateIndex
CREATE UNIQUE INDEX "medias_produits_produit_id_media_id_key" ON "medias_produits"("produit_id", "media_id");

-- CreateIndex
CREATE INDEX "passages_commandes_utilisateur_id_idx" ON "passages_commandes"("utilisateur_id");

-- CreateIndex
CREATE INDEX "passages_commandes_panier_id_idx" ON "passages_commandes"("panier_id");

-- CreateIndex
CREATE INDEX "passages_commandes_statut_idx" ON "passages_commandes"("statut");

-- CreateIndex
CREATE UNIQUE INDEX "commandes_passage_commande_id_key" ON "commandes"("passage_commande_id");

-- CreateIndex
CREATE INDEX "commandes_utilisateur_id_idx" ON "commandes"("utilisateur_id");

-- CreateIndex
CREATE INDEX "commandes_statut_idx" ON "commandes"("statut");

-- CreateIndex
CREATE INDEX "commandes_date_creation_idx" ON "commandes"("date_creation");

-- CreateIndex
CREATE INDEX "articles_commandes_commande_id_idx" ON "articles_commandes"("commande_id");

-- CreateIndex
CREATE INDEX "articles_commandes_vendeur_id_idx" ON "articles_commandes"("vendeur_id");

-- CreateIndex
CREATE INDEX "articles_commandes_statut_idx" ON "articles_commandes"("statut");

-- CreateIndex
CREATE INDEX "lignes_articles_commandes_article_commande_id_idx" ON "lignes_articles_commandes"("article_commande_id");

-- CreateIndex
CREATE INDEX "lignes_articles_commandes_produit_id_idx" ON "lignes_articles_commandes"("produit_id");

-- CreateIndex
CREATE INDEX "lignes_articles_commandes_variante_produit_id_idx" ON "lignes_articles_commandes"("variante_produit_id");

-- CreateIndex
CREATE INDEX "aimes_publication_id_idx" ON "aimes"("publication_id");

-- CreateIndex
CREATE UNIQUE INDEX "aimes_utilisateur_id_publication_id_key" ON "aimes"("utilisateur_id", "publication_id");

-- CreateIndex
CREATE INDEX "commentaires_utilisateur_id_idx" ON "commentaires"("utilisateur_id");

-- CreateIndex
CREATE INDEX "commentaires_publication_id_idx" ON "commentaires"("publication_id");

-- CreateIndex
CREATE INDEX "commentaires_statut_idx" ON "commentaires"("statut");

-- CreateIndex
CREATE INDEX "favoris_publications_publication_id_idx" ON "favoris_publications"("publication_id");

-- CreateIndex
CREATE UNIQUE INDEX "favoris_publications_utilisateur_id_publication_id_key" ON "favoris_publications"("utilisateur_id", "publication_id");

-- CreateIndex
CREATE INDEX "favoris_produits_produit_id_idx" ON "favoris_produits"("produit_id");

-- CreateIndex
CREATE UNIQUE INDEX "favoris_produits_utilisateur_id_produit_id_key" ON "favoris_produits"("utilisateur_id", "produit_id");

-- CreateIndex
CREATE INDEX "abonnements_vendeur_id_idx" ON "abonnements"("vendeur_id");

-- CreateIndex
CREATE UNIQUE INDEX "abonnements_utilisateur_id_vendeur_id_key" ON "abonnements"("utilisateur_id", "vendeur_id");

-- CreateIndex
CREATE INDEX "dossiers_kyc_vendeur_id_idx" ON "dossiers_kyc"("vendeur_id");

-- CreateIndex
CREATE INDEX "dossiers_kyc_statut_idx" ON "dossiers_kyc"("statut");

-- CreateIndex
CREATE INDEX "documents_kyc_dossier_kyc_id_idx" ON "documents_kyc"("dossier_kyc_id");

-- CreateIndex
CREATE INDEX "verifications_kyc_dossier_kyc_id_idx" ON "verifications_kyc"("dossier_kyc_id");

-- CreateIndex
CREATE INDEX "verifications_kyc_statut_idx" ON "verifications_kyc"("statut");

-- CreateIndex
CREATE INDEX "revues_kyc_dossier_kyc_id_idx" ON "revues_kyc"("dossier_kyc_id");

-- CreateIndex
CREATE INDEX "revues_kyc_administrateur_id_idx" ON "revues_kyc"("administrateur_id");

-- CreateIndex
CREATE INDEX "conversations_statut_idx" ON "conversations"("statut");

-- CreateIndex
CREATE INDEX "conversations_date_derniere_activite_idx" ON "conversations"("date_derniere_activite");

-- CreateIndex
CREATE INDEX "participants_conversations_utilisateur_id_idx" ON "participants_conversations"("utilisateur_id");

-- CreateIndex
CREATE INDEX "messages_conversation_id_idx" ON "messages"("conversation_id");

-- CreateIndex
CREATE INDEX "messages_expediteur_id_idx" ON "messages"("expediteur_id");

-- CreateIndex
CREATE INDEX "messages_date_creation_idx" ON "messages"("date_creation");

-- CreateIndex
CREATE INDEX "pieces_jointes_messages_message_id_idx" ON "pieces_jointes_messages"("message_id");

-- CreateIndex
CREATE INDEX "pieces_jointes_messages_media_id_idx" ON "pieces_jointes_messages"("media_id");

-- CreateIndex
CREATE INDEX "signalements_utilisateur_id_idx" ON "signalements"("utilisateur_id");

-- CreateIndex
CREATE INDEX "signalements_publication_id_idx" ON "signalements"("publication_id");

-- CreateIndex
CREATE INDEX "signalements_commentaire_id_idx" ON "signalements"("commentaire_id");

-- CreateIndex
CREATE INDEX "signalements_produit_id_idx" ON "signalements"("produit_id");

-- CreateIndex
CREATE INDEX "signalements_statut_idx" ON "signalements"("statut");

-- CreateIndex
CREATE INDEX "signalements_priorite_idx" ON "signalements"("priorite");

-- CreateIndex
CREATE INDEX "dossiers_moderation_administrateur_id_idx" ON "dossiers_moderation"("administrateur_id");

-- CreateIndex
CREATE INDEX "dossiers_moderation_statut_idx" ON "dossiers_moderation"("statut");

-- CreateIndex
CREATE INDEX "litiges_commande_id_idx" ON "litiges"("commande_id");

-- CreateIndex
CREATE INDEX "litiges_utilisateur_id_idx" ON "litiges"("utilisateur_id");

-- CreateIndex
CREATE INDEX "litiges_statut_idx" ON "litiges"("statut");

-- CreateIndex
CREATE INDEX "preuves_litiges_litige_id_idx" ON "preuves_litiges"("litige_id");

-- CreateIndex
CREATE INDEX "preuves_litiges_media_id_idx" ON "preuves_litiges"("media_id");

-- CreateIndex
CREATE INDEX "notifications_utilisateur_id_idx" ON "notifications"("utilisateur_id");

-- CreateIndex
CREATE INDEX "notifications_type_idx" ON "notifications"("type");

-- CreateIndex
CREATE INDEX "notifications_est_lu_idx" ON "notifications"("est_lu");

-- CreateIndex
CREATE INDEX "notifications_date_creation_idx" ON "notifications"("date_creation");

-- CreateIndex
CREATE UNIQUE INDEX "preferences_notifications_utilisateur_id_type_key" ON "preferences_notifications"("utilisateur_id", "type");

-- CreateIndex
CREATE UNIQUE INDEX "appareils_token_fcm_key" ON "appareils"("token_fcm");

-- CreateIndex
CREATE INDEX "appareils_utilisateur_id_idx" ON "appareils"("utilisateur_id");

-- CreateIndex
CREATE INDEX "appareils_plateforme_idx" ON "appareils"("plateforme");

-- CreateIndex
CREATE INDEX "paiements_passage_commande_id_idx" ON "paiements"("passage_commande_id");

-- CreateIndex
CREATE INDEX "paiements_statut_idx" ON "paiements"("statut");

-- CreateIndex
CREATE INDEX "paiements_date_creation_idx" ON "paiements"("date_creation");

-- CreateIndex
CREATE INDEX "tentatives_paiements_paiement_id_idx" ON "tentatives_paiements"("paiement_id");

-- CreateIndex
CREATE INDEX "tentatives_paiements_statut_idx" ON "tentatives_paiements"("statut");

-- CreateIndex
CREATE UNIQUE INDEX "tentatives_paiements_fournisseur_reference_fournisseur_key" ON "tentatives_paiements"("fournisseur", "reference_fournisseur");

-- CreateIndex
CREATE INDEX "allocations_paiements_commande_id_idx" ON "allocations_paiements"("commande_id");

-- CreateIndex
CREATE UNIQUE INDEX "allocations_paiements_paiement_id_commande_id_key" ON "allocations_paiements"("paiement_id", "commande_id");

-- CreateIndex
CREATE INDEX "sequestres_commande_id_idx" ON "sequestres"("commande_id");

-- CreateIndex
CREATE INDEX "sequestres_statut_idx" ON "sequestres"("statut");

-- CreateIndex
CREATE INDEX "remboursements_commande_id_idx" ON "remboursements"("commande_id");

-- CreateIndex
CREATE INDEX "remboursements_statut_idx" ON "remboursements"("statut");

-- CreateIndex
CREATE INDEX "paniers_utilisateur_id_idx" ON "paniers"("utilisateur_id");

-- CreateIndex
CREATE INDEX "paniers_statut_idx" ON "paniers"("statut");

-- CreateIndex
CREATE INDEX "articles_paniers_variante_produit_id_idx" ON "articles_paniers"("variante_produit_id");

-- CreateIndex
CREATE UNIQUE INDEX "articles_paniers_panier_id_variante_produit_id_key" ON "articles_paniers"("panier_id", "variante_produit_id");

-- CreateIndex
CREATE UNIQUE INDEX "portefeuilles_utilisateur_id_key" ON "portefeuilles"("utilisateur_id");

-- CreateIndex
CREATE INDEX "portefeuilles_statut_idx" ON "portefeuilles"("statut");

-- CreateIndex
CREATE INDEX "transactions_portefeuilles_portefeuille_id_idx" ON "transactions_portefeuilles"("portefeuille_id");

-- CreateIndex
CREATE INDEX "transactions_portefeuilles_type_idx" ON "transactions_portefeuilles"("type");

-- CreateIndex
CREATE INDEX "transactions_portefeuilles_statut_idx" ON "transactions_portefeuilles"("statut");

-- CreateIndex
CREATE INDEX "transactions_portefeuilles_date_creation_idx" ON "transactions_portefeuilles"("date_creation");

-- CreateIndex
CREATE INDEX "retraits_portefeuille_id_idx" ON "retraits"("portefeuille_id");

-- CreateIndex
CREATE INDEX "retraits_statut_idx" ON "retraits"("statut");

-- CreateIndex
CREATE UNIQUE INDEX "comptes_comptables_code_key" ON "comptes_comptables"("code");

-- CreateIndex
CREATE INDEX "comptes_comptables_type_idx" ON "comptes_comptables"("type");

-- CreateIndex
CREATE INDEX "journaux_comptables_date_idx" ON "journaux_comptables"("date");

-- CreateIndex
CREATE INDEX "journaux_comptables_statut_idx" ON "journaux_comptables"("statut");

-- CreateIndex
CREATE INDEX "ecritures_comptables_journal_id_idx" ON "ecritures_comptables"("journal_id");

-- CreateIndex
CREATE INDEX "ecritures_comptables_compte_id_idx" ON "ecritures_comptables"("compte_id");

-- CreateIndex
CREATE INDEX "ecritures_comptables_paiement_id_idx" ON "ecritures_comptables"("paiement_id");

-- CreateIndex
CREATE INDEX "ecritures_comptables_transaction_portefeuille_id_idx" ON "ecritures_comptables"("transaction_portefeuille_id");

-- CreateIndex
CREATE INDEX "publications_vendeur_id_idx" ON "publications"("vendeur_id");

-- CreateIndex
CREATE INDEX "publications_statut_idx" ON "publications"("statut");

-- CreateIndex
CREATE INDEX "publications_date_creation_idx" ON "publications"("date_creation");

-- CreateIndex
CREATE INDEX "medias_publications_media_id_idx" ON "medias_publications"("media_id");

-- CreateIndex
CREATE UNIQUE INDEX "medias_publications_publication_id_media_id_key" ON "medias_publications"("publication_id", "media_id");

-- CreateIndex
CREATE INDEX "publications_produits_produit_id_idx" ON "publications_produits"("produit_id");

-- CreateIndex
CREATE UNIQUE INDEX "publications_produits_publication_id_produit_id_key" ON "publications_produits"("publication_id", "produit_id");

-- CreateIndex
CREATE INDEX "stories_vendeur_id_idx" ON "stories"("vendeur_id");

-- CreateIndex
CREATE INDEX "stories_date_expiration_idx" ON "stories"("date_expiration");

-- CreateIndex
CREATE UNIQUE INDEX "utilisateurs_email_key" ON "utilisateurs"("email");

-- CreateIndex
CREATE UNIQUE INDEX "utilisateurs_telephone_key" ON "utilisateurs"("telephone");

-- CreateIndex
CREATE INDEX "vendeurs_statut_vendeur_idx" ON "vendeurs"("statut_vendeur");

-- CreateIndex
CREATE UNIQUE INDEX "roles_nom_key" ON "roles"("nom");

-- CreateIndex
CREATE INDEX "utilisateur_roles_role_id_idx" ON "utilisateur_roles"("role_id");

-- CreateIndex
CREATE INDEX "adresses_utilisateur_id_idx" ON "adresses"("utilisateur_id");

-- CreateIndex
CREATE INDEX "adresses_type_idx" ON "adresses"("type");

-- CreateIndex
CREATE INDEX "_PortefeuilleToUtilisateur_B_index" ON "_PortefeuilleToUtilisateur"("B");

-- AddForeignKey
ALTER TABLE "journaux_audit" ADD CONSTRAINT "journaux_audit_administrateur_id_fkey" FOREIGN KEY ("administrateur_id") REFERENCES "utilisateurs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "boutiques" ADD CONSTRAINT "boutiques_id_fkey" FOREIGN KEY ("id") REFERENCES "vendeurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "localisations_boutiques" ADD CONSTRAINT "localisations_boutiques_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "horaires_boutiques" ADD CONSTRAINT "horaires_boutiques_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contacts_boutiques" ADD CONSTRAINT "contacts_boutiques_boutique_id_fkey" FOREIGN KEY ("boutique_id") REFERENCES "boutiques"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categories" ADD CONSTRAINT "categories_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "produits" ADD CONSTRAINT "produits_vendeur_id_fkey" FOREIGN KEY ("vendeur_id") REFERENCES "vendeurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "produits" ADD CONSTRAINT "produits_categorie_id_fkey" FOREIGN KEY ("categorie_id") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "variantes_produits" ADD CONSTRAINT "variantes_produits_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medias_produits" ADD CONSTRAINT "medias_produits_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medias_produits" ADD CONSTRAINT "medias_produits_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "medias"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "passages_commandes" ADD CONSTRAINT "passages_commandes_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "passages_commandes" ADD CONSTRAINT "passages_commandes_panier_id_fkey" FOREIGN KEY ("panier_id") REFERENCES "paniers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commandes" ADD CONSTRAINT "commandes_passage_commande_id_fkey" FOREIGN KEY ("passage_commande_id") REFERENCES "passages_commandes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commandes" ADD CONSTRAINT "commandes_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "articles_commandes" ADD CONSTRAINT "articles_commandes_commande_id_fkey" FOREIGN KEY ("commande_id") REFERENCES "commandes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "articles_commandes" ADD CONSTRAINT "articles_commandes_vendeur_id_fkey" FOREIGN KEY ("vendeur_id") REFERENCES "vendeurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lignes_articles_commandes" ADD CONSTRAINT "lignes_articles_commandes_article_commande_id_fkey" FOREIGN KEY ("article_commande_id") REFERENCES "articles_commandes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lignes_articles_commandes" ADD CONSTRAINT "lignes_articles_commandes_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lignes_articles_commandes" ADD CONSTRAINT "lignes_articles_commandes_variante_produit_id_fkey" FOREIGN KEY ("variante_produit_id") REFERENCES "variantes_produits"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "aimes" ADD CONSTRAINT "aimes_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "aimes" ADD CONSTRAINT "aimes_publication_id_fkey" FOREIGN KEY ("publication_id") REFERENCES "publications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commentaires" ADD CONSTRAINT "commentaires_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commentaires" ADD CONSTRAINT "commentaires_publication_id_fkey" FOREIGN KEY ("publication_id") REFERENCES "publications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favoris_publications" ADD CONSTRAINT "favoris_publications_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favoris_publications" ADD CONSTRAINT "favoris_publications_publication_id_fkey" FOREIGN KEY ("publication_id") REFERENCES "publications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favoris_produits" ADD CONSTRAINT "favoris_produits_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favoris_produits" ADD CONSTRAINT "favoris_produits_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "abonnements" ADD CONSTRAINT "abonnements_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "abonnements" ADD CONSTRAINT "abonnements_vendeur_id_fkey" FOREIGN KEY ("vendeur_id") REFERENCES "vendeurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dossiers_kyc" ADD CONSTRAINT "dossiers_kyc_vendeur_id_fkey" FOREIGN KEY ("vendeur_id") REFERENCES "vendeurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documents_kyc" ADD CONSTRAINT "documents_kyc_dossier_kyc_id_fkey" FOREIGN KEY ("dossier_kyc_id") REFERENCES "dossiers_kyc"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "verifications_kyc" ADD CONSTRAINT "verifications_kyc_dossier_kyc_id_fkey" FOREIGN KEY ("dossier_kyc_id") REFERENCES "dossiers_kyc"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "revues_kyc" ADD CONSTRAINT "revues_kyc_dossier_kyc_id_fkey" FOREIGN KEY ("dossier_kyc_id") REFERENCES "dossiers_kyc"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "revues_kyc" ADD CONSTRAINT "revues_kyc_administrateur_id_fkey" FOREIGN KEY ("administrateur_id") REFERENCES "utilisateurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "participants_conversations" ADD CONSTRAINT "participants_conversations_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "participants_conversations" ADD CONSTRAINT "participants_conversations_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_expediteur_id_fkey" FOREIGN KEY ("expediteur_id") REFERENCES "utilisateurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pieces_jointes_messages" ADD CONSTRAINT "pieces_jointes_messages_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pieces_jointes_messages" ADD CONSTRAINT "pieces_jointes_messages_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "medias"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signalements" ADD CONSTRAINT "signalements_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signalements" ADD CONSTRAINT "signalements_publication_id_fkey" FOREIGN KEY ("publication_id") REFERENCES "publications"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signalements" ADD CONSTRAINT "signalements_commentaire_id_fkey" FOREIGN KEY ("commentaire_id") REFERENCES "commentaires"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signalements" ADD CONSTRAINT "signalements_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dossiers_moderation" ADD CONSTRAINT "dossiers_moderation_administrateur_id_fkey" FOREIGN KEY ("administrateur_id") REFERENCES "utilisateurs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "litiges" ADD CONSTRAINT "litiges_commande_id_fkey" FOREIGN KEY ("commande_id") REFERENCES "articles_commandes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "litiges" ADD CONSTRAINT "litiges_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "preuves_litiges" ADD CONSTRAINT "preuves_litiges_litige_id_fkey" FOREIGN KEY ("litige_id") REFERENCES "litiges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "preuves_litiges" ADD CONSTRAINT "preuves_litiges_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "medias"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "preferences_notifications" ADD CONSTRAINT "preferences_notifications_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "appareils" ADD CONSTRAINT "appareils_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "paiements" ADD CONSTRAINT "paiements_passage_commande_id_fkey" FOREIGN KEY ("passage_commande_id") REFERENCES "passages_commandes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tentatives_paiements" ADD CONSTRAINT "tentatives_paiements_paiement_id_fkey" FOREIGN KEY ("paiement_id") REFERENCES "paiements"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "allocations_paiements" ADD CONSTRAINT "allocations_paiements_paiement_id_fkey" FOREIGN KEY ("paiement_id") REFERENCES "paiements"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "allocations_paiements" ADD CONSTRAINT "allocations_paiements_commande_id_fkey" FOREIGN KEY ("commande_id") REFERENCES "commandes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sequestres" ADD CONSTRAINT "sequestres_commande_id_fkey" FOREIGN KEY ("commande_id") REFERENCES "articles_commandes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "remboursements" ADD CONSTRAINT "remboursements_commande_id_fkey" FOREIGN KEY ("commande_id") REFERENCES "articles_commandes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "paniers" ADD CONSTRAINT "paniers_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "articles_paniers" ADD CONSTRAINT "articles_paniers_panier_id_fkey" FOREIGN KEY ("panier_id") REFERENCES "paniers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "articles_paniers" ADD CONSTRAINT "articles_paniers_variante_produit_id_fkey" FOREIGN KEY ("variante_produit_id") REFERENCES "variantes_produits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions_portefeuilles" ADD CONSTRAINT "transactions_portefeuilles_portefeuille_id_fkey" FOREIGN KEY ("portefeuille_id") REFERENCES "portefeuilles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "retraits" ADD CONSTRAINT "retraits_portefeuille_id_fkey" FOREIGN KEY ("portefeuille_id") REFERENCES "portefeuilles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecritures_comptables" ADD CONSTRAINT "ecritures_comptables_journal_id_fkey" FOREIGN KEY ("journal_id") REFERENCES "journaux_comptables"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecritures_comptables" ADD CONSTRAINT "ecritures_comptables_compte_id_fkey" FOREIGN KEY ("compte_id") REFERENCES "comptes_comptables"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecritures_comptables" ADD CONSTRAINT "ecritures_comptables_paiement_id_fkey" FOREIGN KEY ("paiement_id") REFERENCES "paiements"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecritures_comptables" ADD CONSTRAINT "ecritures_comptables_transaction_portefeuille_id_fkey" FOREIGN KEY ("transaction_portefeuille_id") REFERENCES "transactions_portefeuilles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publications" ADD CONSTRAINT "publications_vendeur_id_fkey" FOREIGN KEY ("vendeur_id") REFERENCES "vendeurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medias_publications" ADD CONSTRAINT "medias_publications_publication_id_fkey" FOREIGN KEY ("publication_id") REFERENCES "publications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medias_publications" ADD CONSTRAINT "medias_publications_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "medias"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publications_produits" ADD CONSTRAINT "publications_produits_publication_id_fkey" FOREIGN KEY ("publication_id") REFERENCES "publications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publications_produits" ADD CONSTRAINT "publications_produits_produit_id_fkey" FOREIGN KEY ("produit_id") REFERENCES "produits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stories" ADD CONSTRAINT "stories_vendeur_id_fkey" FOREIGN KEY ("vendeur_id") REFERENCES "vendeurs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stories" ADD CONSTRAINT "stories_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "medias"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clients" ADD CONSTRAINT "clients_id_fkey" FOREIGN KEY ("id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendeurs" ADD CONSTRAINT "vendeurs_id_fkey" FOREIGN KEY ("id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "utilisateur_roles" ADD CONSTRAINT "utilisateur_roles_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "utilisateur_roles" ADD CONSTRAINT "utilisateur_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "adresses" ADD CONSTRAINT "adresses_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_PortefeuilleToUtilisateur" ADD CONSTRAINT "_PortefeuilleToUtilisateur_A_fkey" FOREIGN KEY ("A") REFERENCES "portefeuilles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_PortefeuilleToUtilisateur" ADD CONSTRAINT "_PortefeuilleToUtilisateur_B_fkey" FOREIGN KEY ("B") REFERENCES "utilisateurs"("id") ON DELETE CASCADE ON UPDATE CASCADE;
