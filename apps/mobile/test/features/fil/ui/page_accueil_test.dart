import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/features/fil/ui/pages/page_accueil.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

Map<String, dynamic> _page(List<Map<String, dynamic>> donnees) => {
  'donnees': donnees,
  'pagination': {'total': donnees.length, 'page': 1, 'limite': 10, 'pages': 1},
};

/// Répond aux routes publiques du fil ; mémorise les vues signalées.
class _FauxApi extends ApiClient {
  _FauxApi() : super(Dio());

  final vues = <String>[];

  @override
  Future<T> get<T>(String chemin, {Map<String, dynamic>? query}) async {
    final reponse = switch (chemin) {
      '/publications' => _page([
        {
          'id': 'p1',
          'contenu': 'Nouvelle collection wax',
          'visibilite': 'PUBLIC',
          'nombreVues': 3,
          'dateCreation': DateTime.now().toUtc().toIso8601String(),
          'boutique': {'id': 'b1', 'nom': 'Awa Wax Couture'},
          'medias': <Object>[],
          'produits': <Object>[],
          'likes': 87,
          'commentaires': 12,
        },
      ]),
      '/stories' => _page([
        {
          'id': 's1',
          'dateCreation': DateTime.now().toUtc().toIso8601String(),
          'boutique': {'id': 'b2', 'nom': 'Kribi Perles'},
          'media': {'id': 'm1', 'typeMedia': 'IMAGE', 'url': 'https://x/s.jpg'},
        },
      ]),
      _ => throw StateError('Route inattendue : $chemin'),
    };
    return reponse as T;
  }

  @override
  Future<T> post<T>(String chemin, {Object? data, Options? options}) async {
    vues.add(chemin);
    return null as T;
  }
}

void main() {
  setUp(
    () => VisibilityDetectorController.instance.updateInterval = Duration.zero,
  );

  testWidgets('un visiteur voit le fil public, les stories et une invitation '
      'à se connecter pour les abonnements', (tester) async {
    final api = _FauxApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          utilisateurConnecteProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          theme: ThemeDropp.clair,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PageAccueil(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Pour toi'), findsOneWidget);
    expect(find.text('Kribi Perles'), findsOneWidget);
    // Nom dans l'en-tête de la carte (la légende est un seul Text.rich).
    expect(find.text('Awa Wax Couture'), findsOneWidget);
    expect(find.text('87'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(api.vues, ['/publications/p1/vue']);

    await tester.tap(find.text('Abonnements'));
    await tester.pumpAndSettle();
    expect(find.text('Connecte-toi pour suivre des boutiques'), findsOneWidget);
  });
}
