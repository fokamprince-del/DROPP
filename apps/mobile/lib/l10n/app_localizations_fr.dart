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
}
