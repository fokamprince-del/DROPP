import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/auth/utilisateur.dart';
import 'package:dropp/features/auth/ui/pages/page_confirmation_email.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Utilisateur _awa({String? email, bool verifie = false}) => Utilisateur(
  id: 'u1',
  prenom: 'Awa',
  nom: 'Ngo',
  email: email,
  emailVerifie: verifie,
  telephone: '+237670000001',
  telephoneVerifie: true,
  statutCompte: 'ACTIF',
  estClient: true,
  estVendeur: false,
  statutVendeur: null,
);

/// Compte les envois de code.
class _FauxApi extends ApiClient {
  _FauxApi() : super(Dio());

  final appels = <String>[];

  @override
  Future<T> post<T>(String chemin, {Object? data, Options? options}) async {
    appels.add(chemin);
    return <String, dynamic>{'email': 'awa@exemple.cm'} as T;
  }
}

Future<_FauxApi> _afficher(
  WidgetTester tester,
  Utilisateur utilisateur, {
  bool codeDejaEnvoye = false,
}) async {
  final api = _FauxApi();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        utilisateurConnecteProvider.overrideWithValue(utilisateur),
      ],
      child: MaterialApp(
        theme: ThemeDropp.clair,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PageConfirmationEmail(codeDejaEnvoye: codeDejaEnvoye),
      ),
    ),
  );
  await tester.pump();
  return api;
}

void main() {
  testWidgets('après l’activation : saisie du code, sans renvoi, avec '
      '« Plus tard »', (tester) async {
    final api = await _afficher(
      tester,
      _awa(email: 'awa@exemple.cm'),
      codeDejaEnvoye: true,
    );

    expect(find.text('Confirme ton adresse email'), findsOneWidget);
    expect(find.textContaining('awa@exemple.cm'), findsOneWidget);
    expect(find.text('Plus tard'), findsOneWidget);
    expect(api.appels, isEmpty);
  });

  testWidgets('depuis le profil : le code est demandé à l’ouverture', (
    tester,
  ) async {
    final api = await _afficher(tester, _awa(email: 'awa@exemple.cm'));

    expect(api.appels, ['/auth/email/envoyer-code']);
    expect(find.text('Plus tard'), findsNothing);
  });

  testWidgets('sans email : formulaire d’ajout', (tester) async {
    final api = await _afficher(tester, _awa());

    expect(find.text('Ajoute ton adresse email'), findsOneWidget);
    expect(find.text('Adresse email'), findsOneWidget);
    expect(api.appels, isEmpty);
  });

  testWidgets('email déjà confirmé : proposition de changer', (tester) async {
    await _afficher(tester, _awa(email: 'awa@exemple.cm', verifie: true));

    expect(find.text('Adresse email confirmée'), findsOneWidget);
    expect(find.text('Changer d\'adresse'), findsOneWidget);
  });
}
