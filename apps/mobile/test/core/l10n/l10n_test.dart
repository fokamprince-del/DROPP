import 'package:dropp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _afficher(WidgetTester tester, Locale locale) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Text(AppLocalizations.of(context).navAccueil),
        ),
      ),
    );

void main() {
  testWidgets('affiche le français', (tester) async {
    await _afficher(tester, const Locale('fr'));
    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets("affiche l'anglais", (tester) async {
    await _afficher(tester, const Locale('en'));
    expect(find.text('Home'), findsOneWidget);
  });
}