import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/features/panier/ui/page_panier.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'achat_test.dart';

Future<void> _afficher(WidgetTester tester, Map<String, dynamic> panier) async {
  tester.view
    ..physicalSize = const Size(400, 2000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FauxApi((_, _) => panier)),
        utilisateurConnecteProvider.overrideWithValue(awa),
      ],
      child: MaterialApp(
        theme: ThemeDropp.clair,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PagePanier(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Finder _texte(String attendu) => find.byWidgetPredicate(
  (w) => w is Text && w.data?.replaceAll(RegExp(r'\s'), ' ') == attendu,
);

FilledButton _boutonCommander(WidgetTester tester) => tester.widget(
  find.ancestor(
    of: find.textContaining('Commander'),
    matching: find.byType(FilledButton),
  ),
);

void main() {
  testWidgets('articles par boutique, variante, total et commande possible', (
    tester,
  ) async {
    await _afficher(tester, panierJson());

    expect(find.text('Awa Wax'), findsOneWidget);
    expect(find.text('Kribi Perles'), findsOneWidget);
    expect(find.text('M · Rouge'), findsOneWidget);
    expect(find.text('Prix mis à jour depuis l\'ajout'), findsOneWidget);
    expect(find.text('3 articles'), findsOneWidget);
    expect(_texte('Commander · 62 500 FCFA'), findsOneWidget);
    expect(_boutonCommander(tester).onPressed, isNotNull);
  });

  testWidgets('un article indisponible bloque la commande', (tester) async {
    await _afficher(tester, panierJson(disponible: false));

    expect(
      find.text('Plus disponible : retire-le pour commander'),
      findsOneWidget,
    );
    expect(
      find.text('Retire les articles indisponibles pour commander.'),
      findsOneWidget,
    );
    expect(_boutonCommander(tester).onPressed, isNull);
  });
}
