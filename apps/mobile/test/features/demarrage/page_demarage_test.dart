import 'package:dropp/core/router/routes.dart';
import 'package:dropp/features/demarrage/demarrage.dart';
import 'package:dropp/features/demarrage/page_bienvenue.dart';
import 'package:dropp/features/demarrage/stockage_bienvenue.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FauxStockage implements StockageBienvenue {
  bool vue = false;

  @override
  Future<bool> lireVue() async => vue;

  @override
  Future<void> marquerVue() async => vue = true;
}

void main() {
  testWidgets('les boutons mémorisent la bienvenue et ouvrent l’inscription', (
    tester,
  ) async {
    final stockage = _FauxStockage();
    final routeur = GoRouter(
      initialLocation: Routes.bienvenue,
      routes: [
        GoRoute(
          path: Routes.bienvenue,
          builder: (_, _) => const PageBienvenue(),
        ),
        GoRoute(path: Routes.accueil, builder: (_, _) => const Text('accueil')),
        GoRoute(
          path: Routes.inscription,
          builder: (_, _) => const Text('inscription'),
        ),
      ],
    );
    addTearDown(routeur.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stockageBienvenueProvider.overrideWithValue(stockage),
          dureeMinimaleDemarrageProvider.overrideWithValue(Duration.zero),
        ],
        child: MaterialApp.router(
          theme: ThemeDropp.clair,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: routeur,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suis les boutiques que tu aimes'), findsOneWidget);

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    expect(stockage.vue, isTrue);
    expect(find.text('inscription'), findsOneWidget);
  });

  testWidgets('glisser fait défiler les trois écrans', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeDropp.clair,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PageBienvenue(),
        ),
      ),
    );

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Discute avec le vendeur'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Paie en Mobile Money, en confiance'), findsOneWidget);
  });
}
