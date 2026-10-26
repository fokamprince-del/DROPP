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
}
