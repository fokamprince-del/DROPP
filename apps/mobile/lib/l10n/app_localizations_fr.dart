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
}
