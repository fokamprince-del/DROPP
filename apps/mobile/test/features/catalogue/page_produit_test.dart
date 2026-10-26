import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/features/catalogue/ui/pages/page_produit.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _page(
  List<Object> donnees, {
  Map<String, dynamic>? en,
}) => {
  'donnees': donnees,
  'pagination': {'total': donnees.length, 'page': 1, 'limite': 3, 'pages': 1},
  ...?en,
};

/// Sans médias ni logo : aucune image réseau à charger pendant le test.
class _FauxApi extends ApiClient {
  _FauxApi() : super(Dio());

  @override
  Future<T> get<T>(String chemin, {Map<String, dynamic>? query}) async {
    final Object reponse = switch (chemin) {
      '/produits/pr1' => {
        'id': 'pr1',
        'nom': 'Robe Kaba',
        'prixBase': '25000',
        'boutiqueId': 'b1',
        'variantes': [
          {
            'id': 'v1',
            'attributs': {'taille': 'M'},
            'prix': null,
            'stockDisponible': 5,
          },
          {
            'id': 'v2',
            'attributs': {'taille': 'L'},
            'prix': '27500',
            'stockDisponible': 0,
          },
        ],
        'medias': <Object>[],
      },
      '/produits/pr1/avis' => _page(
        [],
        en: {
          'resume': {
            'moyenne': null,
            'total': 0,
            'repartition': <String, int>{},
          },
        },
      ),
      '/boutiques/b1' => {
        'id': 'b1',
        'nom': 'Awa Wax Couture',
        'statistiques': {'abonnes': 12, 'produits': 3, 'publications': 1},
        'estAbonne': false,
        'estMaBoutique': false,
      },
      _ => throw StateError('Route inattendue : $chemin'),
    };
    return reponse as T;
  }
}

/// Le séparateur de milliers (espace fine insécable) devient une espace.
Finder _texte(String attendu) => find.byWidgetPredicate(
  (w) => w is Text && w.data?.replaceAll(RegExp(r'\s'), ' ') == attendu,
);

FilledButton _bouton(WidgetTester tester, String libelle) => tester.widget(
  find.ancestor(of: find.text(libelle), matching: find.byType(FilledButton)),
);

void main() {
  testWidgets('la variante en stock est présélectionnée ; changer de taille '
      'met à jour le prix et le stock', (tester) async {
    // Téléphone en portrait, assez haut pour construire toute la fiche.
    tester.view
      ..physicalSize = const Size(400, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FauxApi()),
          utilisateurConnecteProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          theme: ThemeDropp.clair,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PageProduit(id: 'pr1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Robe Kaba'), findsOneWidget);
    expect(_texte('25 000 FCFA'), findsOneWidget);
    expect(find.text('En stock'), findsOneWidget);
    // Barre d'achat : variante en stock présélectionnée, bouton actif.
    expect(_bouton(tester, 'Ajouter au panier').onPressed, isNotNull);
    expect(find.text('Taille : M'), findsOneWidget);
    expect(find.text('Awa Wax Couture'), findsOneWidget);
    expect(find.text('Pas encore d\'avis sur ce produit.'), findsOneWidget);

    await tester.tap(find.text('L'));
    await tester.pumpAndSettle();

    expect(_texte('27 500 FCFA'), findsOneWidget);
    // Badge de stock, et bouton d'achat désactivé avec le même libellé.
    expect(find.text('Rupture de stock'), findsNWidgets(2));
    expect(_bouton(tester, 'Rupture de stock').onPressed, isNull);
    expect(find.text('Taille : L'), findsOneWidget);
  });
}
