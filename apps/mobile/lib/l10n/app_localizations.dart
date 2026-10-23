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
