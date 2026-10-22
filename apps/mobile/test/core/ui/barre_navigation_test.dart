import 'package:dropp/core/theme/theme_dropp.dart';
import 'package:dropp/core/ui/barre_navigation.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _afficher(
  WidgetTester tester, {
  int index = 0,
  int panier = 0,
  int messages = 0,
  ValueChanged<int>? surSelection,
}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: ThemeDropp.clair,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: BarreNavigation(
            indexSelectionne: index,
            nombrePanier: panier,
            nombreMessages: messages,
            surSelection: surSelection ?? (_) {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('affiche les libellés de la maquette', (tester) async {
    await _afficher(tester);
    for (final libelle in ['Accueil', 'Découvrir', 'Messages', 'Profil']) {
      expect(find.text(libelle), findsOneWidget);
    }
  });

  testWidgets('signale l’index touché', (tester) async {
    int? touche;
    await _afficher(tester, surSelection: (i) => touche = i);
    await tester.tap(find.text('Messages'));
    expect(touche, 3);
  });

  testWidgets('aucune pastille quand les compteurs sont à zéro',
      (tester) async {
    await _afficher(tester);
    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('plafonne l’affichage à 99+', (tester) async {
    await _afficher(tester, panier: 120, messages: 3);
    expect(find.text('99+'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}