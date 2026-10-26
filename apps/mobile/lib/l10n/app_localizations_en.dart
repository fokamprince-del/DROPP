// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get nomApp => 'DROPP';

  @override
  String get navAccueil => 'Home';

  @override
  String get navDecouvrir => 'Discover';

  @override
  String get navPanier => 'Cart';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfil => 'Profile';

  @override
  String get baselineApp => 'Cameroon\'s marketplace in your pocket';

  @override
  String navPanierArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Cart, $_temp0';
  }

  @override
  String navMessagesNonLus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
    );
    return 'Messages, $_temp0';
  }

  @override
  String get champPrenom => 'First name';

  @override
  String get champNom => 'Last name';

  @override
  String get champSexe => 'Gender';

  @override
  String get sexeMasculin => 'Male';

  @override
  String get sexeFeminin => 'Female';

  @override
  String get sexeAutre => 'Other';

  @override
  String get champTelephone => 'Phone';

  @override
  String get champEmailFacultatif => 'Email (optional)';

  @override
  String get champMotDePasse => 'Password';

  @override
  String get erreurRequis => 'This field is required';

  @override
  String get erreurTelephoneInvalide => 'Invalid phone number';

  @override
  String get erreurEmailInvalide => 'Invalid email address';

  @override
  String get erreurMotDePasseCourt => 'At least 8 characters';

  @override
  String get erreurCodeIncomplet => 'Enter the 6 digits of the code';

  @override
  String get forceMotDePasse1 =>
      'Weak. Use at least 8 characters, with letters and numbers.';

  @override
  String get forceMotDePasse2 => 'Fair. Add numbers or capital letters.';

  @override
  String get forceMotDePasse3 => 'Strong. Add a symbol to make it very strong.';

  @override
  String get forceMotDePasse4 => 'Very strong.';

  @override
  String get champCode => 'Verification code';

  @override
  String get motDePasseAfficher => 'Show password';

  @override
  String get motDePasseMasquer => 'Hide password';

  @override
  String get champIdentifiant => 'Phone or email';

  @override
  String get champNouveauMotDePasse => 'New password';

  @override
  String get erreurIdentifiantInvalide => 'Invalid number or email';

  @override
  String get erreurReseau => 'No internet connection.';

  @override
  String get erreurDelai =>
      'The server is taking too long to respond. Try again.';

  @override
  String get erreurTropDeTentatives =>
      'Too many attempts. Wait a minute before trying again.';

  @override
  String get erreurServeur =>
      'The server is having a problem. Try again later.';

  @override
  String get erreurInterdit => 'This account can\'t be used right now.';

  @override
  String get erreurRequeteInvalide => 'Check the information you entered.';

  @override
  String get erreurInconnue => 'Something went wrong. Try again.';

  @override
  String get erreurIdentifiantsIncorrects => 'Incorrect credentials.';

  @override
  String get erreurCompteExistant =>
      'An account already exists with this number or email.';

  @override
  String get erreurCodeIncorrect =>
      'Incorrect or expired code. Check it or request a new one.';

  @override
  String get erreurCodeExpire =>
      'Code expired or too many attempts. Request a new code.';

  @override
  String get erreurVerificationExpiree => 'Verification expired. Start over.';

  @override
  String get erreurRequeteEnCours =>
      'An identical request is in progress. Please wait.';

  @override
  String get sessionExpiree => 'Your session has expired. Sign in again.';

  @override
  String get inscriptionTitre => 'Create your account';

  @override
  String get inscriptionSousTitre =>
      'An activation code will be sent to you by SMS.';

  @override
  String get inscriptionBouton => 'Get the code by SMS';

  @override
  String get inscriptionConditions =>
      'By continuing, you accept the terms of use.';

  @override
  String get jaiDejaUnCompte => 'I already have an account';

  @override
  String get connexionTitre => 'Welcome back';

  @override
  String get connexionSousTitre => 'Sign in with your number or email.';

  @override
  String get connexionBouton => 'Sign in';

  @override
  String get creerUnCompte => 'Create an account';

  @override
  String get motDePasseOublieLien => 'Forgot password?';

  @override
  String get codeTitre => 'Enter the code received by SMS';

  @override
  String codeEnvoyeA(String numero) {
    return 'Sent to $numero. Valid for 5 minutes.';
  }

  @override
  String get codeEnvoyeAuCompte =>
      'A code has just been sent by SMS to your account\'s number. Valid for 5 minutes.';

  @override
  String get codeVerifier => 'Verify';

  @override
  String get renvoyerCode => 'Resend code';

  @override
  String renvoyerCodeDans(String duree) {
    return 'Resend code in $duree';
  }

  @override
  String get oubliTitre => 'Forgot password';

  @override
  String get oubliSousTitre =>
      'Enter your number or email. If an account exists, a code will be sent.';

  @override
  String get oubliSecurite =>
      'For security, all your sessions will be signed out after the change.';

  @override
  String get oubliBouton => 'Get a code';

  @override
  String get reinitTitre => 'New password';

  @override
  String get reinitSousTitre =>
      'Enter the code you received, then choose a new password.';

  @override
  String get reinitBouton => 'Change password';

  @override
  String get reessayer => 'Retry';

  @override
  String get rienAAfficher => 'Nothing to show yet.';

  @override
  String get tempsInstant => 'just now';

  @override
  String tempsMinutes(int n) {
    return '$n min ago';
  }

  @override
  String tempsHeures(int n) {
    return '$n h ago';
  }

  @override
  String tempsJours(int n) {
    return '$n d ago';
  }

  @override
  String get filPourToi => 'For you';

  @override
  String get filAbonnements => 'Following';

  @override
  String get filPourToiVide => 'No posts yet. Check back soon!';

  @override
  String get filAbonnementsVideTitre => 'Your feed is still empty';

  @override
  String get filAbonnementsVideTexte =>
      'Follow shops to see their latest items here first.';

  @override
  String get filDecouvrirBoutiques => 'Discover shops';

  @override
  String get filConnexionTitre => 'Log in to follow shops';

  @override
  String get filConnexionTexte =>
      'New posts from the shops you follow will show up here.';

  @override
  String get publicationTitre => 'Post';

  @override
  String publicationOuvrir(String boutique) {
    return 'Open $boutique\'s post';
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
      other: '$countString views',
      one: '1 view',
      zero: 'no views',
    );
    return '$_temp0';
  }

  @override
  String publicationLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
      zero: 'No likes',
    );
    return '$_temp0';
  }

  @override
  String publicationCommentaires(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
      zero: 'No comments',
    );
    return '$_temp0';
  }

  @override
  String get publicationAbonnes => 'Followers only';

  @override
  String get publicationProduits => 'In this post';

  @override
  String get mediaVideo => 'Video';

  @override
  String mediaPosition(int position, int total) {
    return '$position/$total';
  }

  @override
  String get videoIllisible => 'Couldn\'t play the video. Tap to try again.';

  @override
  String storyDe(String boutique) {
    return '$boutique\'s story';
  }

  @override
  String storyNouvelle(String boutique) {
    return '$boutique, new story';
  }

  @override
  String get storySuivante => 'Next story';

  @override
  String get storyPrecedente => 'Previous story';

  @override
  String get storyFermer => 'Close';

  @override
  String get storyIllisible => 'This story can\'t be displayed.';
}
