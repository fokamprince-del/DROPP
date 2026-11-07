import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/api/api_exception.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/router/routes.dart';
import 'package:dropp/core/upload/service_upload.dart';
import 'package:dropp/features/vendeur/data/kyc_repository.dart';
import 'package:dropp/features/vendeur/data/modeles_kyc.dart';
import 'package:dropp/features/vendeur/ui/pages/page_kyc_information.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FauxKyc extends KycRepository {
  _FauxKyc({this.extraction, this.erreurExtraction, this.erreurConfirmation})
    : super(ApiClient(Dio()), ServiceUpload(Dio()));

  final ResultatExtractionCni? extraction;
  final ApiException? erreurExtraction;
  final ApiException? erreurConfirmation;
  DonneesCni? confirmees;

  @override
  Future<DossierKyc?> monDossier() async => const DossierKyc(
    id: 'd1',
    statut: StatutDossierKyc.enAttente,
    documents: [
      DocumentKyc(id: 'a', type: TypeDocumentKyc.cniRecto, statut: 'SOUMIS'),
      DocumentKyc(id: 'b', type: TypeDocumentKyc.cniVerso, statut: 'SOUMIS'),
    ],
  );

  @override
  Future<ResultatExtractionCni> extraireCni() async {
    if (erreurExtraction != null) throw erreurExtraction!;
    return extraction!;
  }

  @override
  Future<void> confirmerCni(DonneesCni donnees) async => confirmees = donnees;
}

Future<void> _afficher(WidgetTester tester, _FauxKyc kyc) async {
  final routeur = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const PageKycInformations()),
      GoRoute(
        path: Routes.kycSelfie,
        builder: (_, _) => const Text('page selfie'),
      ),
    ],
  );
  addTearDown(routeur.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        kycRepositoryProvider.overrideWithValue(kyc),
        utilisateurConnecteProvider.overrideWithValue(null),
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
}

Future<void> _saisir(WidgetTester tester, int champ, String texte) async {
  final cible = find.byType(TextFormField).at(champ);
  await tester.ensureVisible(cible);
  await tester.enterText(cible, texte);
}

Future<void> _remplirTout(
  WidgetTester tester, {
  String numero = 'ab-123456',
}) async {
  await _saisir(tester, 0, 'NGO BASSA');
  await _saisir(tester, 1, 'Awa');
  await _saisir(tester, 2, numero);
  await _saisir(tester, 3, '21051990');
  await _saisir(tester, 4, 'Douala');
  await _saisir(tester, 5, '02012020');
  await _saisir(tester, 6, '02012099');
}

Future<void> _cocherEtConfirmer(WidgetTester tester) async {
  final case_ = find.byType(CheckboxListTile);
  await tester.ensureVisible(case_);
  await tester.tap(case_);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Confirmer et continuer'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'lecture automatique : animation, champs désactivés, puis préremplissage',
    (tester) async {
      final kyc = _FauxKyc(
        extraction: ResultatExtractionCni(
          donnees: DonneesCni(
            nomLegal: 'NGO BASSA',
            prenomLegal: 'Awa',
            numeroCni: 'ab123456',
            dateNaissance: DateTime.utc(1990, 5, 21),
          ),
          confiance: 92,
        ),
      );
      await _afficher(tester, kyc);

      await tester.tap(find.text('Remplir mes informations automatiquement'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Lecture de ta carte en cours…'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).enabled,
        isFalse,
      );

      // L'animation tourne en boucle : on avance le temps sans attendre le calme.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('NGO BASSA'), findsOneWidget);
      expect(find.text('AB123456'), findsOneWidget);
      expect(find.text('21/05/1990'), findsOneWidget);
      expect(find.text('Lu sur ta carte : vérifie'), findsNWidgets(4));
      expect(find.text('Non lu : à compléter'), findsNWidgets(3));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).enabled,
        isTrue,
      );
    },
  );

  testWidgets('carte introuvable : message clair, saisie manuelle possible', (
    tester,
  ) async {
    final kyc = _FauxKyc(
      erreurExtraction: const ApiException(
        type: TypeErreurApi.introuvable,
        message: 'Not found',
        statusCode: 404,
      ),
    );
    await _afficher(tester, kyc);

    await tester.tap(find.text('Remplir mes informations automatiquement'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Nous ne trouvons pas ta carte. Reviens à l'étape précédente et importe-la de nouveau.",
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      isTrue,
    );
  });

  testWidgets('saisie manuelle : la confirmation explicite est obligatoire', (
    tester,
  ) async {
    final kyc = _FauxKyc();
    await _afficher(tester, kyc);
    await _remplirTout(tester);

    final bouton = find.widgetWithText(FilledButton, 'Confirmer et continuer');
    expect(tester.widget<FilledButton>(bouton).onPressed, isNull);

    await _cocherEtConfirmer(tester);

    expect(kyc.confirmees?.numeroCni, 'AB123456');
    expect(kyc.confirmees?.dateNaissance, DateTime.utc(1990, 5, 21));
    expect(kyc.confirmees?.dateExpiration, DateTime.utc(2030, 1, 2));
    expect(find.text('page selfie'), findsOneWidget);
  });

  testWidgets('une information invalide empêche la confirmation', (
    tester,
  ) async {
    final kyc = _FauxKyc();
    await _afficher(tester, kyc);
    await _remplirTout(tester, numero: 'AB12');

    await _cocherEtConfirmer(tester);

    expect(find.text('6 à 20 lettres ou chiffres'), findsOneWidget);
    expect(kyc.confirmees, isNull);
    expect(find.text('page selfie'), findsNothing);
  });

  testWidgets("un refus du serveur est traduit et amené à l'écran", (
    tester,
  ) async {
    final kyc = _FauxKyc(
      erreurConfirmation: const ApiException(
        type: TypeErreurApi.requeteInvalide,
        message: 'x',
        statusCode: 400,
        details: ['Vous devez avoir au moins 18 ans pour vendre sur DROPP.'],
      ),
    );
    await _afficher(tester, kyc);
    await _remplirTout(tester);
    await _cocherEtConfirmer(tester);

    expect(
      find.text('Tu dois avoir au moins 18 ans pour vendre sur DROPP.'),
      findsOneWidget,
    );
    expect(find.text('page selfie'), findsNothing);
  });
}
