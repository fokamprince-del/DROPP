// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get nomApp => 'DROPP';

  @override
  String get navAccueil => 'Accueil';

  @override
  String get navDecouvrir => 'Découvrir';

  @override
  String get navPanier => 'Panier';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfil => 'Profil';

  @override
  String get baselineApp => 'Le marché camerounais dans ta poche';

  @override
  String navPanierArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return 'Panier, $_temp0';
  }

  @override
  String navMessagesNonLus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non lus',
      one: '1 non lu',
    );
    return 'Messages, $_temp0';
  }

  @override
  String get champPrenom => 'Prénom';

  @override
  String get champNom => 'Nom';

  @override
  String get champSexe => 'Sexe';

  @override
  String get sexeMasculin => 'Homme';

  @override
  String get sexeFeminin => 'Femme';

  @override
  String get sexeAutre => 'Autre';

  @override
  String get champTelephone => 'Téléphone';

  @override
  String get champEmailFacultatif => 'Email (facultatif)';

  @override
  String get champMotDePasse => 'Mot de passe';

  @override
  String get erreurRequis => 'Ce champ est obligatoire';

  @override
  String get erreurTelephoneInvalide => 'Numéro de téléphone invalide';

  @override
  String get erreurEmailInvalide => 'Adresse email invalide';

  @override
  String get erreurMotDePasseCourt => '8 caractères minimum';

  @override
  String get erreurCodeIncomplet => 'Saisis les 6 chiffres du code';

  @override
  String get forceMotDePasse1 =>
      'Faible. Utilise 8 caractères minimum, avec lettres et chiffres.';

  @override
  String get forceMotDePasse2 =>
      'Moyen. Ajoute des chiffres ou des majuscules.';

  @override
  String get forceMotDePasse3 =>
      'Solide. Ajoute un symbole pour le rendre très solide.';

  @override
  String get forceMotDePasse4 => 'Très solide.';

  @override
  String get champCode => 'Code de vérification';

  @override
  String get motDePasseAfficher => 'Afficher le mot de passe';

  @override
  String get motDePasseMasquer => 'Masquer le mot de passe';

  @override
  String get champIdentifiant => 'Téléphone ou email';

  @override
  String get champNouveauMotDePasse => 'Nouveau mot de passe';

  @override
  String get erreurIdentifiantInvalide => 'Numéro ou email invalide';

  @override
  String get erreurReseau => 'Pas de connexion internet.';

  @override
  String get erreurDelai =>
      'Le serveur met trop de temps à répondre. Réessaie.';

  @override
  String get erreurTropDeTentatives =>
      'Trop de tentatives. Patiente une minute avant de réessayer.';

  @override
  String get erreurServeur =>
      'Le serveur rencontre un problème. Réessaie plus tard.';

  @override
  String get erreurInterdit =>
      'Ce compte ne peut pas être utilisé pour le moment.';

  @override
  String get erreurRequeteInvalide => 'Vérifie les informations saisies.';

  @override
  String get erreurInconnue => 'Une erreur est survenue. Réessaie.';

  @override
  String get erreurIdentifiantsIncorrects => 'Identifiants incorrects.';

  @override
  String get erreurCompteExistant =>
      'Un compte existe déjà avec ce numéro ou cet email.';

  @override
  String get erreurCodeIncorrect =>
      'Code incorrect ou expiré. Vérifie-le ou demande-en un nouveau.';

  @override
  String get erreurCodeExpire =>
      'Code expiré ou trop d\'essais. Demande un nouveau code.';

  @override
  String get erreurVerificationExpiree =>
      'Vérification expirée. Recommence depuis le début.';

  @override
  String get erreurRequeteEnCours =>
      'Une demande identique est en cours. Patiente un instant.';

  @override
  String get sessionExpiree => 'Ta session a expiré. Reconnecte-toi.';

  @override
  String get inscriptionTitre => 'Crée ton compte';

  @override
  String get inscriptionSousTitre =>
      'Un code d\'activation te sera envoyé par SMS.';

  @override
  String get inscriptionBouton => 'Recevoir le code par SMS';

  @override
  String get inscriptionConditions =>
      'En continuant, tu acceptes les conditions d\'utilisation.';

  @override
  String get jaiDejaUnCompte => 'J\'ai déjà un compte';

  @override
  String get connexionTitre => 'Content de te revoir';

  @override
  String get connexionSousTitre => 'Connecte-toi avec ton numéro ou ton email.';

  @override
  String get connexionBouton => 'Se connecter';

  @override
  String get creerUnCompte => 'Créer un compte';

  @override
  String get motDePasseOublieLien => 'Mot de passe oublié ?';

  @override
  String get codeTitre => 'Entre le code reçu par SMS';

  @override
  String codeEnvoyeA(String numero) {
    return 'Envoyé au $numero. Valable 5 minutes.';
  }

  @override
  String get codeEnvoyeAuCompte =>
      'Un code vient d\'être envoyé par SMS au numéro de ton compte. Valable 5 minutes.';

  @override
  String get codeVerifier => 'Vérifier';

  @override
  String get renvoyerCode => 'Renvoyer le code';

  @override
  String renvoyerCodeDans(String duree) {
    return 'Renvoyer le code dans $duree';
  }

  @override
  String get oubliTitre => 'Mot de passe oublié';

  @override
  String get oubliSousTitre =>
      'Saisis ton numéro ou ton email. Si un compte existe, un code te sera envoyé.';

  @override
  String get oubliSecurite =>
      'Par sécurité, toutes tes sessions seront déconnectées après le changement.';

  @override
  String get oubliBouton => 'Recevoir un code';

  @override
  String get reinitTitre => 'Nouveau mot de passe';

  @override
  String get reinitSousTitre =>
      'Saisis le code reçu, puis choisis un nouveau mot de passe.';

  @override
  String get reinitBouton => 'Changer le mot de passe';

  @override
  String get reessayer => 'Réessayer';

  @override
  String get rienAAfficher => 'Rien à afficher pour le moment.';

  @override
  String get tempsInstant => 'à l\'instant';

  @override
  String tempsMinutes(int n) {
    return 'il y a $n min';
  }

  @override
  String tempsHeures(int n) {
    return 'il y a $n h';
  }

  @override
  String tempsJours(int n) {
    return 'il y a $n j';
  }

  @override
  String get filPourToi => 'Pour toi';

  @override
  String get filAbonnements => 'Abonnements';

  @override
  String get filPourToiVide =>
      'Aucune publication pour le moment. Reviens bientôt !';

  @override
  String get filAbonnementsVideTitre => 'Ton fil est encore vide';

  @override
  String get filAbonnementsVideTexte =>
      'Suis des boutiques pour voir leurs nouveautés ici en premier.';

  @override
  String get filDecouvrirBoutiques => 'Découvrir des boutiques';

  @override
  String get filConnexionTitre => 'Connecte-toi pour suivre des boutiques';

  @override
  String get filConnexionTexte =>
      'Les nouveautés des boutiques que tu suis apparaîtront ici.';

  @override
  String get publicationTitre => 'Publication';

  @override
  String publicationOuvrir(String boutique) {
    return 'Voir la publication de $boutique';
  }

  @override
  String publicationVues(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString vues',
      one: '1 vue',
      zero: 'aucune vue',
    );
    return '$_temp0';
  }

  @override
  String publicationLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count j\'aime',
      one: '1 j\'aime',
      zero: 'Aucun j\'aime',
    );
    return '$_temp0';
  }

  @override
  String publicationCommentaires(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commentaires',
      one: '1 commentaire',
      zero: 'Aucun commentaire',
    );
    return '$_temp0';
  }

  @override
  String get publicationAbonnes => 'Réservée aux abonnés';

  @override
  String get publicationProduits => 'Dans cette publication';

  @override
  String get mediaVideo => 'Vidéo';

  @override
  String mediaPosition(int position, int total) {
    return '$position/$total';
  }

  @override
  String get videoIllisible =>
      'Impossible de lire la vidéo. Touche pour réessayer.';

  @override
  String storyDe(String boutique) {
    return 'Story de $boutique';
  }

  @override
  String storyNouvelle(String boutique) {
    return '$boutique, nouvelle story';
  }

  @override
  String get storySuivante => 'Story suivante';

  @override
  String get storyPrecedente => 'Story précédente';

  @override
  String get storyFermer => 'Fermer';

  @override
  String get storyIllisible => 'Cette story ne peut pas être affichée.';

  @override
  String get annuler => 'Annuler';

  @override
  String get supprimer => 'Supprimer';

  @override
  String get erreurActionInterdite =>
      'Action impossible avec ce compte. Vérifie ton numéro de téléphone.';

  @override
  String get erreurContenuIntrouvable => 'Ce contenu n\'est plus disponible.';

  @override
  String get favoriAjouter => 'Ajouter aux favoris';

  @override
  String get favoriRetirer => 'Retirer des favoris';

  @override
  String get partageTitre => 'Partager';

  @override
  String get partageCopierLien => 'Copier le lien';

  @override
  String get partageLienCopie => 'Lien copié';

  @override
  String get partageWhatsAppAbsent =>
      'Impossible d\'ouvrir WhatsApp sur cet appareil.';

  @override
  String partageTexte(String boutique, String lien) {
    return 'Découvre $boutique sur DROPP : $lien';
  }

  @override
  String commentairesTitre(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commentaires',
      one: '1 commentaire',
      zero: 'Commentaires',
    );
    return '$_temp0';
  }

  @override
  String get commentairesVide => 'Pas encore de commentaire. Sois le premier !';

  @override
  String commentairesVoirReponses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voir $count autres réponses',
      one: 'Voir 1 autre réponse',
    );
    return '$_temp0';
  }

  @override
  String get commentairesConnexion => 'Connecte-toi pour commenter';

  @override
  String get commentaireRepondre => 'Répondre';

  @override
  String get commentaireCreateur => 'Créateur';

  @override
  String commentaireReponseA(String auteur) {
    return 'Réponse à $auteur';
  }

  @override
  String get commentairePlaceholder =>
      'Ajouter un commentaire… (@pseudo pour mentionner)';

  @override
  String get commentairePublier => 'Publier';

  @override
  String get commentaireSupprimerTitre => 'Supprimer ce commentaire ?';

  @override
  String get commentaireSupprimerTexte =>
      'Il disparaîtra pour tout le monde, avec ses réponses.';

  @override
  String get rechercheIndice => 'Robe, téléphone, boutique…';

  @override
  String get rechercheEffacer => 'Effacer la recherche';

  @override
  String get decouvrirProduits => 'Produits';

  @override
  String get decouvrirBoutiques => 'Boutiques';

  @override
  String get catalogueTout => 'Tout';

  @override
  String get catalogueVide => 'Aucun produit avec ces filtres';

  @override
  String get catalogueEffacerFiltres => 'Effacer les filtres';

  @override
  String get boutiquesVide => 'Aucune boutique trouvée';

  @override
  String get triRecents => 'Plus récents';

  @override
  String get triPrixCroissant => 'Prix croissant';

  @override
  String get triPrixDecroissant => 'Prix décroissant';

  @override
  String get triPopulaires => 'Les plus aimés';

  @override
  String get filtresTitre => 'Filtres';

  @override
  String get filtresPrix => 'Prix (FCFA)';

  @override
  String get filtresPrixMin => 'Min';

  @override
  String get filtresPrixMax => 'Max';

  @override
  String get filtresTri => 'Trier par';

  @override
  String get filtresEnStock => 'En stock uniquement';

  @override
  String get filtresReinitialiser => 'Réinitialiser';

  @override
  String get filtresAppliquer => 'Voir les produits';

  @override
  String prixMoinsDe(String montant) {
    return 'Moins de $montant';
  }

  @override
  String prixPlusDe(String montant) {
    return 'Plus de $montant';
  }

  @override
  String prixAPartirDe(String prix) {
    return 'À partir de $prix';
  }

  @override
  String get stockEnStock => 'En stock';

  @override
  String get stockRupture => 'Rupture de stock';

  @override
  String stockPlusQue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Plus que $count en stock',
      one: 'Plus qu\'1 en stock',
    );
    return '$_temp0';
  }

  @override
  String varianteNumero(int numero) {
    return 'Option $numero';
  }

  @override
  String get avisTitre => 'Avis';

  @override
  String avisTitreNombre(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Avis ($count)',
      zero: 'Avis',
    );
    return '$_temp0';
  }

  @override
  String avisNombre(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '1 avis',
      zero: 'aucun avis',
    );
    return '$_temp0';
  }

  @override
  String get avisAucun => 'Pas encore d\'avis sur ce produit.';

  @override
  String avisVoirTous(int count) {
    return 'Voir les $count avis';
  }

  @override
  String avisNote(int note) {
    return '$note étoiles sur 5';
  }

  @override
  String avisMoyenne(String note) {
    return 'Note moyenne : $note sur 5';
  }

  @override
  String get avisAchatVerifie => 'Achat vérifié';

  @override
  String get boutiqueSuivre => 'Suivre';

  @override
  String get boutiqueAbonne => 'Abonné';

  @override
  String boutiqueAbonnes(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString abonnés',
      one: '1 abonné',
      zero: 'aucun abonné',
    );
    return '$_temp0';
  }

  @override
  String boutiqueAbonnesLibelle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'abonnés',
      one: 'abonné',
    );
    return '$_temp0';
  }

  @override
  String boutiqueProduitsLibelle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'produits',
      one: 'produit',
    );
    return '$_temp0';
  }

  @override
  String get boutiquePublications => 'Publications';

  @override
  String get boutiqueAucunProduit => 'Aucun produit en ligne pour le moment.';

  @override
  String get boutiqueAucunePublication => 'Aucune publication pour le moment.';

  @override
  String get abonnementsTitre => 'Mes abonnements';

  @override
  String get abonnementsVideTitre => 'Tu ne suis encore aucune boutique';

  @override
  String abonnementsDepuis(String date) {
    return 'Abonné depuis le $date';
  }

  @override
  String get champEmail => 'Adresse email';

  @override
  String get erreurEmailUtilisee => 'Cette adresse email est déjà utilisée.';

  @override
  String get erreurMotDePasseIncorrect => 'Mot de passe incorrect.';

  @override
  String get emailTitre => 'Confirme ton adresse email';

  @override
  String emailSousTitre(String email) {
    return 'Nous avons envoyé un code à $email. Elle servira à récupérer ton compte.';
  }

  @override
  String get emailConfirmer => 'Confirmer';

  @override
  String get emailConfirmee => 'Adresse email confirmée.';

  @override
  String get emailPlusTard => 'Plus tard';

  @override
  String get emailChangerLien => 'Changer d\'adresse';

  @override
  String get emailAjouterTitre => 'Ajoute ton adresse email';

  @override
  String get emailChangerTitre => 'Changer d\'adresse email';

  @override
  String get emailChangerSousTitre =>
      'Un code sera envoyé à la nouvelle adresse. L\'ancienne reste active jusqu\'à la confirmation.';

  @override
  String get emailRecevoirCode => 'Recevoir le code';

  @override
  String get emailTitreConfirmee => 'Adresse email confirmée';

  @override
  String emailDejaConfirmee(String email) {
    return '$email est confirmée. Tu peux t\'en servir pour récupérer ton compte.';
  }

  @override
  String get enregistrer => 'Enregistrer';

  @override
  String get aujourdhui => 'Aujourd\'hui';

  @override
  String get hier => 'Hier';

  @override
  String get mediaGaleriePhoto => 'Photo de la galerie';

  @override
  String get mediaPrendrePhoto => 'Prendre une photo';

  @override
  String get mediaGalerieVideo => 'Vidéo de la galerie';

  @override
  String get mediaFilmer => 'Filmer une vidéo';

  @override
  String fichierTropGros(int mo) {
    return 'Fichier trop volumineux : $mo Mo au maximum.';
  }

  @override
  String get fichierFormatRefuse =>
      'Format non pris en charge. Choisis une photo (JPEG, PNG, WebP) ou une vidéo (MP4, MOV).';

  @override
  String get panierVide => 'Ton panier est vide';

  @override
  String get panierVideTexte =>
      'Ajoute des articles depuis la fiche d\'un produit.';

  @override
  String panierNombreArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String get panierAjouter => 'Ajouter au panier';

  @override
  String get panierChoisirOption => 'Choisis une option';

  @override
  String get panierAjoute => 'Ajouté au panier';

  @override
  String get panierVoir => 'Voir';

  @override
  String get panierStockInsuffisant => 'Stock insuffisant pour cette quantité.';

  @override
  String panierStockRestant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Plus que $count en stock : réduis la quantité',
      one: 'Plus qu\'1 en stock : réduis la quantité',
    );
    return '$_temp0';
  }

  @override
  String get panierIndisponible => 'Plus disponible : retire-le pour commander';

  @override
  String get panierPrixModifie => 'Prix mis à jour depuis l\'ajout';

  @override
  String panierQuantite(int count) {
    return 'Quantité : $count';
  }

  @override
  String get panierMoins => 'Diminuer la quantité';

  @override
  String get panierPlus => 'Augmenter la quantité';

  @override
  String get panierSousTotal => 'Sous-total';

  @override
  String get panierLivraison => 'Livraison';

  @override
  String get panierLivraisonPlusTard => 'Calculée à l\'étape suivante';

  @override
  String get panierTotal => 'Total';

  @override
  String get panierProtection =>
      'Paiement protégé : le vendeur est payé après la livraison.';

  @override
  String get panierNonCommandable =>
      'Retire les articles indisponibles pour commander.';

  @override
  String panierCommander(String prix) {
    return 'Commander · $prix';
  }

  @override
  String get commanderTitre => 'Passer la commande ?';

  @override
  String commanderTexte(int minutes) {
    return 'Les articles sont réservés pendant $minutes minutes, le temps du paiement. Sans paiement, la commande est annulée et le stock rendu.';
  }

  @override
  String get commanderConfirmer => 'Commander';

  @override
  String get commanderPanierChange =>
      'Ton panier a changé (stock ou prix). Vérifie-le avant de commander.';

  @override
  String get commandesTitre => 'Mes commandes';

  @override
  String get commandesVide => 'Aucune commande pour le moment';

  @override
  String get commandeTitre => 'Commande';

  @override
  String commandeDu(String date) {
    return 'Commande du $date';
  }

  @override
  String get commandeAPayerAvant => 'À payer avant l\'annulation automatique';

  @override
  String get commandeDelaiDepasse =>
      'Délai dépassé : la commande va être annulée.';

  @override
  String get commandePaiementBientot =>
      'Le paiement par Mobile Money (MTN MoMo, Orange Money) arrive très bientôt dans l\'application.';

  @override
  String get commandeAnnuler => 'Annuler la commande';

  @override
  String get commandeAnnulerTitre => 'Annuler cette commande ?';

  @override
  String get commandeAnnulerTexte => 'Les articles seront remis en vente.';

  @override
  String get commandeGarder => 'Garder';

  @override
  String get commandeDejaTraitee => 'Cette commande a déjà été traitée.';

  @override
  String get statutEnAttentePaiement => 'En attente de paiement';

  @override
  String get statutNouvelle => 'Payée';

  @override
  String get statutEnCours => 'En préparation';

  @override
  String get statutExpediee => 'Expédiée';

  @override
  String get statutLivree => 'Livrée';

  @override
  String get statutAnnulee => 'Annulée';

  @override
  String get statutEnLitige => 'En litige';

  @override
  String get adressesTitre => 'Mes adresses';

  @override
  String get adressesVide => 'Aucune adresse enregistrée';

  @override
  String get adressesVideTexte =>
      'Ajoute une adresse pour être livré plus vite.';

  @override
  String get adresseAjouter => 'Ajouter une adresse';

  @override
  String get adresseModifier => 'Modifier l\'adresse';

  @override
  String get adresseSupprimerTitre => 'Supprimer cette adresse ?';

  @override
  String get adresseLivraison => 'Livraison';

  @override
  String get adresseFacturation => 'Facturation';

  @override
  String get adresseAutre => 'Autre';

  @override
  String get adressePrincipale => 'Principale';

  @override
  String get adresseLigne1 => 'Quartier, rue, point de repère';

  @override
  String get adresseLigne2 => 'Complément (bâtiment, étage…)';

  @override
  String get adresseVille => 'Ville';

  @override
  String get adresseRegion => 'Région';

  @override
  String get adressePays => 'Pays';

  @override
  String get adresseCodePostal => 'Code postal';

  @override
  String get adresseDefinirPrincipale => 'Adresse principale';

  @override
  String get avisANoterTitre => 'Avis à laisser';

  @override
  String get avisANoterVide => 'Rien à noter pour le moment';

  @override
  String get avisANoterVideTexte => 'Tes articles livrés apparaîtront ici.';

  @override
  String avisCommandeLe(String date) {
    return 'commandé le $date';
  }

  @override
  String get avisNoter => 'Noter';

  @override
  String get avisTonAvis => 'Ton avis';

  @override
  String get avisCommentaireIndice =>
      'Qualité, taille, livraison… (facultatif)';

  @override
  String get avisPublier => 'Publier l\'avis';

  @override
  String get avisModifier => 'Modifier mon avis';

  @override
  String get avisSupprimerTitre => 'Supprimer ton avis ?';

  @override
  String get avisMesActions => 'Gérer mon avis';

  @override
  String get avisNonModifiable =>
      'Un avis n\'est plus modifiable après 30 jours.';

  @override
  String get avisDejaDonne => 'Tu as déjà donné ton avis sur cet article.';

  @override
  String get boutiqueMessage => 'Message';

  @override
  String get boutiqueEcrire => 'Écrire à la boutique';

  @override
  String get conversationsVide => 'Aucune conversation';

  @override
  String get conversationsVideTexte =>
      'Écris à une boutique depuis la fiche d\'un produit ou sa page.';

  @override
  String get conversationCompteSupprime => 'Compte supprimé';

  @override
  String messageDeMoi(String texte) {
    return 'Toi : $texte';
  }

  @override
  String get messagePhoto => '📷 Photo';

  @override
  String get messageVideo => '🎥 Vidéo';

  @override
  String get messagePieceJointe => '📎 Pièce jointe';

  @override
  String get messageIndice => 'Écris un message…';

  @override
  String get messageEnvoyer => 'Envoyer';

  @override
  String get messageJoindre => 'Joindre une photo ou une vidéo';

  @override
  String messagePiecesMax(int max) {
    return '$max fichiers au plus par message.';
  }

  @override
  String messageFichiers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
    );
    return '$_temp0';
  }

  @override
  String get messageEnvoi => 'Envoi…';

  @override
  String get messageEnvoye => 'Envoyé';

  @override
  String get messageLu => 'Lu';

  @override
  String get messageEnvoiInterdit =>
      'Impossible d\'écrire dans cette conversation.';

  @override
  String get discussionDebut => 'Début de la conversation';

  @override
  String get discussionFermee => 'Cette conversation est fermée.';

  @override
  String get plusDOptions => 'Plus d\'options';

  @override
  String get discussionEcrit => 'en train d\'écrire…';

  @override
  String get signaler => 'Signaler';

  @override
  String get signalerTitre => 'Signaler ce contenu';

  @override
  String get signalementDescriptionObligatoire =>
      'Explique ce qui ne va pas (obligatoire)';

  @override
  String get signalementDescriptionFacultative => 'Précisions (facultatif)';

  @override
  String get signalementEnvoyer => 'Envoyer le signalement';

  @override
  String get signalementAnonyme =>
      'La personne signalée ne saura pas que c\'est toi.';

  @override
  String get signalementEnvoye => 'Merci. Notre équipe va examiner ce contenu.';

  @override
  String get signalementDejaFait =>
      'Tu as déjà signalé ce contenu : il est en cours d\'examen.';

  @override
  String get signalementPropreContenu =>
      'Tu ne peux pas signaler ton propre contenu.';

  @override
  String get signalementsTitre => 'Mes signalements';

  @override
  String get signalementsVide => 'Aucun signalement';

  @override
  String get signalementOuvert => 'Reçu';

  @override
  String get signalementEnCours => 'En examen';

  @override
  String get signalementTraite => 'Traité';

  @override
  String get signalementRejete => 'Sans suite';

  @override
  String get ciblePublication => 'Publication';

  @override
  String get cibleCommentaire => 'Commentaire';

  @override
  String get cibleProduit => 'Produit';

  @override
  String get cibleBoutique => 'Boutique';

  @override
  String get cibleMessage => 'Message';

  @override
  String get bloquer => 'Bloquer';

  @override
  String get debloquer => 'Débloquer';

  @override
  String bloquerTitre(String nom) {
    return 'Bloquer $nom ?';
  }

  @override
  String get bloquerTexte =>
      'Vous ne pourrez plus vous écrire, et cette personne ne pourra plus commenter tes publications ni te suivre. Tu pourras la débloquer depuis ton profil.';

  @override
  String bloqueConfirme(String nom) {
    return '$nom est bloqué.';
  }

  @override
  String get bloquesTitre => 'Utilisateurs bloqués';

  @override
  String get bloquesVide => 'Personne n\'est bloqué';

  @override
  String get bloquesVideTexte =>
      'Tu peux bloquer quelqu\'un depuis une conversation ou une page boutique.';

  @override
  String bloqueLe(String date) {
    return 'Bloqué le $date';
  }

  @override
  String get notificationsTitre => 'Notifications';

  @override
  String notificationsNonLues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications non lues',
      one: '1 notification non lue',
    );
    return '$_temp0';
  }

  @override
  String get notificationsToutLire => 'Tout marquer comme lu';

  @override
  String get notificationsPreferences => 'Préférences de notification';

  @override
  String get notificationsVide => 'Aucune notification';

  @override
  String get notificationNonLue => 'Non lue';

  @override
  String get preferenceMessages => 'Messages';

  @override
  String get preferenceSocial => 'J\'aime, commentaires, abonnés';

  @override
  String get preferencePromotions => 'Promotions';

  @override
  String get preferencesExplication =>
      'Choisis les notifications envoyées sur ton téléphone. Elles restent toutes visibles dans l\'application. Les commandes, paiements et alertes de sécurité sont toujours envoyés.';

  @override
  String get favorisTitre => 'Mes favoris';

  @override
  String get favorisProduitsVide => 'Aucun produit en favori';

  @override
  String get favorisPublicationsVide => 'Aucune publication enregistrée';

  @override
  String get favoriPlusEnVente => 'plus en vente';

  @override
  String get profilPhoto => 'Photo de profil';

  @override
  String get profilChangerPhoto => 'Changer la photo';

  @override
  String get profilRetirerPhoto => 'Retirer la photo';

  @override
  String get profilModifier => 'Modifier le profil';

  @override
  String get profilSansPseudo => 'Pas encore de pseudo';

  @override
  String get profilEmail => 'Adresse email';

  @override
  String get profilEmailAbsent => 'Aucune adresse email';

  @override
  String profilEmailAConfirmer(String email) {
    return '$email · à confirmer';
  }

  @override
  String get profilSectionAchats => 'ACHATS';

  @override
  String get profilSectionSocial => 'SUIVIS ET FAVORIS';

  @override
  String get profilSectionCompte => 'COMPTE';

  @override
  String get profilSectionVendeur => 'VENDRE SUR DROPP';

  @override
  String get profilEspaceVendeur => 'Espace vendeur';

  @override
  String get profilDevenirVendeur => 'Devenir vendeur';

  @override
  String get deconnexion => 'Se déconnecter';

  @override
  String get deconnexionTitre => 'Se déconnecter de cet appareil ?';

  @override
  String get champPseudo => 'Pseudo (@)';

  @override
  String get pseudoDisponible => 'Ce pseudo est disponible.';

  @override
  String get pseudoPris => 'Ce pseudo est déjà pris.';

  @override
  String get pseudoReserve => 'Ce pseudo est réservé. Choisis-en un autre.';

  @override
  String get pseudoFormat =>
      '3 à 30 caractères : lettres minuscules, chiffres, « _ » ou « . ».';

  @override
  String get securiteTitre => 'Sécurité';

  @override
  String get securiteIdentifiants => 'IDENTIFIANTS';

  @override
  String get securiteAppareils => 'APPAREILS CONNECTÉS';

  @override
  String get securiteCompte => 'COMPTE';

  @override
  String get motDePasseChanger => 'Changer le mot de passe';

  @override
  String get motDePasseChangerTexte =>
      'Tes autres appareils seront déconnectés.';

  @override
  String get champMotDePasseActuel => 'Mot de passe actuel';

  @override
  String get motDePasseChange => 'Mot de passe changé.';

  @override
  String get erreurMotDePasseActuel => 'Mot de passe actuel incorrect.';

  @override
  String get erreurMotDePasseRefuse =>
      'Ce mot de passe n\'est pas accepté : il doit être différent de l\'actuel et plus solide.';

  @override
  String get telephoneChanger => 'Changer de numéro';

  @override
  String get telephoneChangerTexte =>
      'Un code sera envoyé par SMS au nouveau numéro.';

  @override
  String get telephoneDejaUtilise =>
      'Ce numéro est déjà utilisé par un autre compte.';

  @override
  String get telephoneChange => 'Numéro de téléphone changé.';

  @override
  String get appareilInconnu => 'Appareil';

  @override
  String get appareilActuel => 'Cet appareil';

  @override
  String appareilDerniereUtilisation(String quand) {
    return 'Dernière activité : $quand';
  }

  @override
  String get deconnecterPartout => 'Déconnecter tous les appareils';

  @override
  String get deconnecterPartoutTitre => 'Déconnecter tous les appareils ?';

  @override
  String get deconnecterPartoutTexte =>
      'Y compris celui-ci : il faudra te reconnecter partout.';

  @override
  String get compteSupprimer => 'Supprimer mon compte';

  @override
  String get compteSupprimerTitre => 'Supprimer ton compte ?';

  @override
  String get compteSupprimerTexte =>
      'Ton profil, tes favoris, tes messages et ta boutique éventuelle seront supprimés. C\'est définitif. Saisis ton mot de passe pour confirmer.';

  @override
  String get compteSupprimerConfirmer => 'Supprimer définitivement';

  @override
  String get compteSupprime => 'Ton compte a été supprimé.';

  @override
  String get compteCommandesEnCours =>
      'Des commandes sont encore en cours : attends leur livraison ou annule-les avant de supprimer ton compte.';

  @override
  String get bienvenue1Titre => 'Suis les boutiques que tu aimes';

  @override
  String get bienvenue1Texte =>
      'Découvre leurs nouveautés en vidéo, discute avec le vendeur et achète en Mobile Money.';

  @override
  String get bienvenue2Titre => 'Discute avec le vendeur';

  @override
  String get bienvenue2Texte =>
      'Pose tes questions, demande une taille ou une couleur avant de commander, directement dans l\'app.';

  @override
  String get bienvenue3Titre => 'Paie en Mobile Money, en confiance';

  @override
  String get bienvenue3Texte =>
      'MTN MoMo ou Orange Money. Ton argent est bloqué jusqu\'à la réception du colis.';

  @override
  String bienvenuePage(int numero, int total) {
    return 'Page $numero sur $total';
  }

  @override
  String get vendeurTitre => 'Devenir vendeur';

  @override
  String get vendeurIntro =>
      'Vends tes produits aux clients de DROPP. Nous vérifions ton identité pour protéger les acheteurs.';

  @override
  String get vendeurPrerequisTitre => 'Ce qu\'il te faut';

  @override
  String get vendeurPrerequisTelephone => 'Un téléphone vérifié';

  @override
  String get vendeurPrerequisCni => 'Ta carte nationale d\'identité (CNI)';

  @override
  String get vendeurPrerequisSelfie => 'Un selfie de vérification';

  @override
  String get vendeurDelai =>
      'Validation par l\'équipe DROPP : prévois 24 à 48 h.';

  @override
  String get vendeurCommencer => 'Commencer';

  @override
  String get vendeurSuite => 'Prochaine étape : l\'envoi de tes documents.';

  @override
  String get vendeurSuspendu =>
      'Ton compte vendeur est suspendu. Contacte le support DROPP.';
}
