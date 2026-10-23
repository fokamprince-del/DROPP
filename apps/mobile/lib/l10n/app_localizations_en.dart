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
}
