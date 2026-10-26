import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @nomApp.
  ///
  /// In fr, this message translates to:
  /// **'DROPP'**
  String get nomApp;

  /// No description provided for @navAccueil.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navAccueil;

  /// No description provided for @navDecouvrir.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get navDecouvrir;

  /// No description provided for @navPanier.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get navPanier;

  /// No description provided for @navMessages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfil.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfil;

  /// No description provided for @baselineApp.
  ///
  /// In fr, this message translates to:
  /// **'Le marché camerounais dans ta poche'**
  String get baselineApp;

  /// No description provided for @navPanierArticles.
  ///
  /// In fr, this message translates to:
  /// **'Panier, {count, plural, =1{1 article} other{{count} articles}}'**
  String navPanierArticles(int count);

  /// No description provided for @navMessagesNonLus.
  ///
  /// In fr, this message translates to:
  /// **'Messages, {count, plural, =1{1 non lu} other{{count} non lus}}'**
  String navMessagesNonLus(int count);

  /// No description provided for @champPrenom.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get champPrenom;

  /// No description provided for @champNom.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get champNom;

  /// No description provided for @champSexe.
  ///
  /// In fr, this message translates to:
  /// **'Sexe'**
  String get champSexe;

  /// No description provided for @sexeMasculin.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get sexeMasculin;

  /// No description provided for @sexeFeminin.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get sexeFeminin;

  /// No description provided for @sexeAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get sexeAutre;

  /// No description provided for @champTelephone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get champTelephone;

  /// No description provided for @champEmailFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Email (facultatif)'**
  String get champEmailFacultatif;

  /// No description provided for @champMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get champMotDePasse;

  /// No description provided for @erreurRequis.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire'**
  String get erreurRequis;

  /// No description provided for @erreurTelephoneInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide'**
  String get erreurTelephoneInvalide;

  /// No description provided for @erreurEmailInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide'**
  String get erreurEmailInvalide;

  /// No description provided for @erreurMotDePasseCourt.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum'**
  String get erreurMotDePasseCourt;

  /// No description provided for @erreurCodeIncomplet.
  ///
  /// In fr, this message translates to:
  /// **'Saisis les 6 chiffres du code'**
  String get erreurCodeIncomplet;

  /// No description provided for @forceMotDePasse1.
  ///
  /// In fr, this message translates to:
  /// **'Faible. Utilise 8 caractères minimum, avec lettres et chiffres.'**
  String get forceMotDePasse1;

  /// No description provided for @forceMotDePasse2.
  ///
  /// In fr, this message translates to:
  /// **'Moyen. Ajoute des chiffres ou des majuscules.'**
  String get forceMotDePasse2;

  /// No description provided for @forceMotDePasse3.
  ///
  /// In fr, this message translates to:
  /// **'Solide. Ajoute un symbole pour le rendre très solide.'**
  String get forceMotDePasse3;

  /// No description provided for @forceMotDePasse4.
  ///
  /// In fr, this message translates to:
  /// **'Très solide.'**
  String get forceMotDePasse4;

  /// No description provided for @champCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification'**
  String get champCode;

  /// No description provided for @motDePasseAfficher.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get motDePasseAfficher;

  /// No description provided for @motDePasseMasquer.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get motDePasseMasquer;

  /// No description provided for @champIdentifiant.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone ou email'**
  String get champIdentifiant;

  /// No description provided for @champNouveauMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get champNouveauMotDePasse;

  /// No description provided for @erreurIdentifiantInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Numéro ou email invalide'**
  String get erreurIdentifiantInvalide;

  /// No description provided for @erreurReseau.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet.'**
  String get erreurReseau;

  /// No description provided for @erreurDelai.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur met trop de temps à répondre. Réessaie.'**
  String get erreurDelai;

  /// No description provided for @erreurTropDeTentatives.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patiente une minute avant de réessayer.'**
  String get erreurTropDeTentatives;

  /// No description provided for @erreurServeur.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur rencontre un problème. Réessaie plus tard.'**
  String get erreurServeur;

  /// No description provided for @erreurInterdit.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte ne peut pas être utilisé pour le moment.'**
  String get erreurInterdit;

  /// No description provided for @erreurRequeteInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie les informations saisies.'**
  String get erreurRequeteInvalide;

  /// No description provided for @erreurInconnue.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessaie.'**
  String get erreurInconnue;

  /// No description provided for @erreurIdentifiantsIncorrects.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants incorrects.'**
  String get erreurIdentifiantsIncorrects;

  /// No description provided for @erreurCompteExistant.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec ce numéro ou cet email.'**
  String get erreurCompteExistant;

  /// No description provided for @erreurCodeIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect ou expiré. Vérifie-le ou demande-en un nouveau.'**
  String get erreurCodeIncorrect;

  /// No description provided for @erreurCodeExpire.
  ///
  /// In fr, this message translates to:
  /// **'Code expiré ou trop d\'essais. Demande un nouveau code.'**
  String get erreurCodeExpire;

  /// No description provided for @erreurVerificationExpiree.
  ///
  /// In fr, this message translates to:
  /// **'Vérification expirée. Recommence depuis le début.'**
  String get erreurVerificationExpiree;

  /// No description provided for @erreurRequeteEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Une demande identique est en cours. Patiente un instant.'**
  String get erreurRequeteEnCours;

  /// No description provided for @sessionExpiree.
  ///
  /// In fr, this message translates to:
  /// **'Ta session a expiré. Reconnecte-toi.'**
  String get sessionExpiree;

  /// No description provided for @inscriptionTitre.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton compte'**
  String get inscriptionTitre;

  /// No description provided for @inscriptionSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Un code d\'activation te sera envoyé par SMS.'**
  String get inscriptionSousTitre;

  /// No description provided for @inscriptionBouton.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code par SMS'**
  String get inscriptionBouton;

  /// No description provided for @inscriptionConditions.
  ///
  /// In fr, this message translates to:
  /// **'En continuant, tu acceptes les conditions d\'utilisation.'**
  String get inscriptionConditions;

  /// No description provided for @jaiDejaUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai déjà un compte'**
  String get jaiDejaUnCompte;

  /// No description provided for @connexionTitre.
  ///
  /// In fr, this message translates to:
  /// **'Content de te revoir'**
  String get connexionTitre;

  /// No description provided for @connexionSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi avec ton numéro ou ton email.'**
  String get connexionSousTitre;

  /// No description provided for @connexionBouton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get connexionBouton;

  /// No description provided for @creerUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get creerUnCompte;

  /// No description provided for @motDePasseOublieLien.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get motDePasseOublieLien;

  /// No description provided for @codeTitre.
  ///
  /// In fr, this message translates to:
  /// **'Entre le code reçu par SMS'**
  String get codeTitre;

  /// No description provided for @codeEnvoyeA.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé au {numero}. Valable 5 minutes.'**
  String codeEnvoyeA(String numero);

  /// No description provided for @codeEnvoyeAuCompte.
  ///
  /// In fr, this message translates to:
  /// **'Un code vient d\'être envoyé par SMS au numéro de ton compte. Valable 5 minutes.'**
  String get codeEnvoyeAuCompte;

  /// No description provided for @codeVerifier.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get codeVerifier;

  /// No description provided for @renvoyerCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get renvoyerCode;

  /// No description provided for @renvoyerCodeDans.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans {duree}'**
  String renvoyerCodeDans(String duree);

  /// No description provided for @oubliTitre.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get oubliTitre;

  /// No description provided for @oubliSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Saisis ton numéro ou ton email. Si un compte existe, un code te sera envoyé.'**
  String get oubliSousTitre;

  /// No description provided for @oubliSecurite.
  ///
  /// In fr, this message translates to:
  /// **'Par sécurité, toutes tes sessions seront déconnectées après le changement.'**
  String get oubliSecurite;

  /// No description provided for @oubliBouton.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir un code'**
  String get oubliBouton;

  /// No description provided for @reinitTitre.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get reinitTitre;

  /// No description provided for @reinitSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Saisis le code reçu, puis choisis un nouveau mot de passe.'**
  String get reinitSousTitre;

  /// No description provided for @reinitBouton.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get reinitBouton;

  /// No description provided for @bienvenue1Titre.
  ///
  /// In fr, this message translates to:
  /// **'Suis les boutiques que tu aimes'**
  String get bienvenue1Titre;

  /// No description provided for @bienvenue1Texte.
  ///
  /// In fr, this message translates to:
  /// **'Découvre leurs nouveautés en vidéo, discute avec le vendeur et achète en Mobile Money.'**
  String get bienvenue1Texte;

  /// No description provided for @bienvenue2Titre.
  ///
  /// In fr, this message translates to:
  /// **'Discute avec le vendeur'**
  String get bienvenue2Titre;

  /// No description provided for @bienvenue2Texte.
  ///
  /// In fr, this message translates to:
  /// **'Pose tes questions, demande une taille ou une couleur avant de commander, directement dans l\'app.'**
  String get bienvenue2Texte;

  /// No description provided for @bienvenue3Titre.
  ///
  /// In fr, this message translates to:
  /// **'Paie en Mobile Money, en confiance'**
  String get bienvenue3Titre;

  /// No description provided for @bienvenue3Texte.
  ///
  /// In fr, this message translates to:
  /// **'MTN MoMo ou Orange Money. Ton argent est bloqué jusqu\'à la réception du colis.'**
  String get bienvenue3Texte;

  /// No description provided for @bienvenuePage.
  ///
  /// In fr, this message translates to:
  /// **'Page {numero} sur {total}'**
  String bienvenuePage(int numero, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
