import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/api/api_exception.dart';
import 'package:dropp/core/auth/jetons.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/router/routes.dart';
import 'package:dropp/features/auth/application/flux_verification.dart';
import 'package:dropp/features/auth/data/auth_repository.dart';
import 'package:dropp/features/auth/data/modeles_auth.dart';
import 'package:dropp/features/auth/ui/pages/page_connexion.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FauxDepot extends AuthRepository {
  _FauxDepot() : super(ApiClient(Dio()));

  /// Un `ResultatConnexion` à renvoyer, ou une `ApiException` à lever.
  Object? reponse;
  String? dernierIdentifiant;

  @override
  Future<ResultatConnexion> connecter({
    required String identifiant,
    required String motDePasse,
  }) async {
    dernierIdentifiant = identifiant;
    final r = reponse;
    if (r is ApiException) throw r;
    return r! as ResultatConnexion;
  }
}

class _FausseSession extends SessionNotifier {
  Jetons? recus;

  @override
  EtatSession build() => const SessionAnonyme();

  @override
  Future<void> ouvrir(Jetons jetons) async => recus = jetons;
}

Future<ProviderContainer> _lancer(WidgetTester tester, _FauxDepot depot) async {
  final routeur = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const PageConnexion()),
      GoRoute(
        path: Routes.verificationTelephone,
        builder: (_, _) => const Text('page code'),
      ),
    ],
  );
  addTearDown(routeur.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(depot),
        sessionProvider.overrideWith(_FausseSession.new),
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
  return ProviderScope.containerOf(tester.element(find.byType(PageConnexion)));
}

Future<void> _saisirEtValider(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), '670 00 00 01');
  await tester.enterText(find.byType(TextFormField).at(1), 'motdepasse1');
  await tester.ensureVisible(find.byType(FilledButton));
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('identifiants refusés : message traduit, pas celui du serveur', (
    tester,
  ) async {
    final depot = _FauxDepot()
      ..reponse = const ApiException(
        type: TypeErreurApi.nonAuthentifie,
        message: 'Invalid credentials',
        statusCode: 401,
      );
    await _lancer(tester, depot);
    await _saisirEtValider(tester);

    expect(find.text('Identifiants incorrects.'), findsOneWidget);
    expect(find.text('Invalid credentials'), findsNothing);
    expect(depot.dernierIdentifiant, '+237670000001');
  });

  testWidgets('compte non vérifié : passe à la saisie du code', (tester) async {
    final depot = _FauxDepot()..reponse = const VerificationRequise('vt9');
    final conteneur = await _lancer(tester, depot);
    await _saisirEtValider(tester);

    expect(find.text('page code'), findsOneWidget);
    final flux = conteneur.read(fluxVerificationProvider);
    expect(flux?.verificationToken, 'vt9');
    expect(flux?.objectif, ObjectifVerification.activation);
  });

  testWidgets('connexion réussie : la session est ouverte', (tester) async {
    final depot = _FauxDepot()
      ..reponse = const ConnexionReussie(
        Jetons(accessToken: 'a', refreshToken: 'r'),
      );
    final conteneur = await _lancer(tester, depot);
    await _saisirEtValider(tester);

    final session = conteneur.read(sessionProvider.notifier) as _FausseSession;
    expect(session.recus?.accessToken, 'a');
  });

  testWidgets('un identifiant invalide n\'appelle pas le serveur', (
    tester,
  ) async {
    final depot = _FauxDepot();
    await _lancer(tester, depot);

    await tester.enterText(find.byType(TextFormField).at(0), '12');
    await tester.enterText(find.byType(TextFormField).at(1), 'motdepasse1');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Numéro ou email invalide'), findsOneWidget);
    expect(depot.dernierIdentifiant, isNull);
  });
}
