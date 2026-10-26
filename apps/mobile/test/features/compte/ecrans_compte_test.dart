import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/temps_reel/temps_reel.dart';
import 'package:dropp/features/notifications/ui/notifications_ui.dart';
import 'package:dropp/features/profil/ui/page_profil.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../achat/achat_test.dart' show FauxApi, awa;
import 'compte_test.dart' show tempsReelFactice;

Future<void> _afficher(
  WidgetTester tester,
  Widget page,
  FauxApi api,
  TempsReel tempsReel,
) async {
  tester.view
    ..physicalSize = const Size(400, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        utilisateurConnecteProvider.overrideWithValue(awa),
        tempsReelProvider.overrideWithValue(tempsReel),
      ],
      child: MaterialApp(
        theme: ThemeDropp.clair,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Map<String, dynamic> _notification(String id, {bool lue = false}) => {
  'id': id,
  'type': 'SOCIAL',
  'titre': 'Nouvel abonné $id',
  'contenu': 'Paul s’est abonné à votre boutique.',
  'donnees': <String, dynamic>{},
  'estLu': lue,
  'dateCreation': DateTime.now().toUtc().toIso8601String(),
};

void main() {
  testWidgets('profil : identité, pseudo absent, email à ajouter, sections', (
    tester,
  ) async {
    await _afficher(
      tester,
      const PageProfil(),
      FauxApi(
        (_, _) => {
          'id': 'u1',
          'prenom': 'Awa',
          'nom': 'Ngo',
          'pseudo': null,
          'email': null,
          'telephone': '+237670000001',
          'photoProfilUrl': null,
          'dateInscription': '2026-09-01T10:00:00.000Z',
        },
      ),
      tempsReelFactice(),
    );

    expect(find.text('Awa Ngo'), findsOneWidget);
    expect(find.text('Pas encore de pseudo'), findsOneWidget);
    expect(find.text('Aucune adresse email'), findsOneWidget);
    for (final entree in [
      'Mes commandes',
      'Mes adresses',
      'Mes favoris',
      'Sécurité',
      'Utilisateurs bloqués',
      'Devenir vendeur',
      'Se déconnecter',
    ]) {
      expect(find.text(entree), findsOneWidget, reason: entree);
    }
  });

  testWidgets('notifications : toucher marque lue ; une notification reçue '
      'en direct s’ajoute en tête', (tester) async {
    final tr = tempsReelFactice();
    final api = FauxApi(
      (m, chemin) => switch ((m, chemin)) {
        ('GET', '/notifications') => {
          'donnees': [_notification('n1'), _notification('n2', lue: true)],
          'nonLues': 1,
          'pagination': {'total': 2, 'page': 1, 'limite': 20, 'pages': 1},
        },
        ('GET', '/notifications/compteur') => {'nonLues': 1},
        _ => {'nonLues': 0},
      },
    );
    await _afficher(tester, const PageNotifications(), api, tr);

    expect(find.text('Nouvel abonné n1'), findsOneWidget);
    await tester.tap(find.text('Nouvel abonné n1'));
    await tester.pump();
    expect(api.appels, contains('PATCH /notifications/n1/lue'));

    tr.simuler('notification:nouvelle', _notification('n3'));
    await tester.pump();
    expect(find.text('Nouvel abonné n3'), findsOneWidget);
  });
}
