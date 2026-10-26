import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/utils/format.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les séparateurs de milliers varient selon la version d'intl (espace
/// insécable ou fine) : on les compare comme des espaces.
String espaces(String texte) => texte.replaceAll(RegExp(r'\s'), ' ');

void main() {
  test('prix au format de la maquette', () {
    expect(espaces(formaterPrix(25000)), '25 000 FCFA');
    expect(espaces(formaterPrix(4500.6)), '4 501 FCFA');
    expect(formaterPrix(0), '0 FCFA');
  });

  test('durée de vidéo', () {
    expect(formaterDuree(const Duration(seconds: 42)), '0:42');
    expect(formaterDuree(const Duration(minutes: 12, seconds: 5)), '12:05');
  });

  test('temps relatif en français', () {
    final l10n = lookupAppLocalizations(const Locale('fr'));
    final maintenant = DateTime(2026, 10, 26, 12);
    String depuis(Duration ecart) =>
        tempsRelatif(l10n, maintenant.subtract(ecart), maintenant: maintenant);

    expect(depuis(const Duration(seconds: 20)), 'à l\'instant');
    expect(depuis(const Duration(minutes: 5)), 'il y a 5 min');
    expect(depuis(const Duration(hours: 3)), 'il y a 3 h');
    expect(depuis(const Duration(days: 2)), 'il y a 2 j');
  });
}
