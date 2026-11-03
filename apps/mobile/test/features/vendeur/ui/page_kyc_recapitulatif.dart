import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/api/api_exception.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/router/routes.dart';
import 'package:dropp/core/upload/service_upload.dart';
import 'package:dropp/features/vendeur/application/brouillon_kyc.dart';
import 'package:dropp/features/vendeur/data/kyc_repository.dart';
import 'package:dropp/features/vendeur/data/modeles_kyc.dart';
import 'package:dropp/features/vendeur/ui/pages/page_kyc_recapitulatif.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

DossierKyc _dossierComplet({
  StatutDossierKyc statut = StatutDossierKyc.enAttente,
  bool selfie = true,
}) => DossierKyc(
  id: 'd1',
  statut: statut,
  documents: [
    const DocumentKyc(
      id: 'a',
      type: TypeDocumentKyc.cniRecto,
      statut: 'SOUMIS',
    ),
    const DocumentKyc(
      id: 'b',
      type: TypeDocumentKyc.cniVerso,
      statut: 'SOUMIS',
    ),
    if (selfie)
      const DocumentKyc(
        id: 'c',
        type: TypeDocumentKyc.photoFaciale,
        statut: 'SOUMIS',
      ),
  ],
  donnees: DonneesCni(
    nomLegal: 'NGO BASSA',
    prenomLegal: 'Awa',
    numeroCni: 'AB123456',
    dateNaissance: DateTime.utc(1990, 5, 21),
    lieuNaissance: 'Douala',
    dateEtablissement: DateTime.utc(2020, 1, 2),
    dateExpiration: DateTime.utc(2030, 1, 2),
  ),
);

class _FauxKyc extends KycRepository {
  _FauxKyc(this.dossier) : super(ApiClient(Dio()), ServiceUpload(Dio()));

  DossierKyc dossier;
  final cles = <String>[];

  /// Erreurs à lever, dans l'ordre, avant un succès.
  final echecs = <ApiException>[];

  /// Le serveur a enregistré la soumission malgré l'erreur (réponse perdue).
  bool enregistreMalgreEchec = false;

  /// Pour retenir la réponse et tester le double appui.
  Completer<void>? attente;

  DossierKyc _soumis() => DossierKyc(
    id: dossier.id,
    statut: StatutDossierKyc.enCoursVerification,
    documents: dossier.documents,
    donnees: dossier.donnees,
  );

  @override
  Future<DossierKyc?> monDossier() async => dossier;

  @override
  Future<StatutDossierKyc> soumettre({
    required bool consentement,
    required String cleIdempotence,
  }) async {
    cles.add(cleIdempotence);
    await attente?.future;
    if (echecs.isNotEmpty) {
      if (enregistreMalgreEchec) dossier = _soumis();
      throw echecs.removeAt(0);
    }
    dossier = _soumis();
    return StatutDossierKyc.enCoursVerification;
  }
}

Future<ProviderContainer> _afficher(WidgetTester tester, _FauxKyc kyc) async {
  final routeur = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const PageKycRecapitulatif()),
      GoRoute(
        path: Routes.devenirVendeur,
        builder: (_, _) => const Text('page dossier'),
      ),
      GoRoute(path: Routes.kycCni, builder: (_, _) => const Text('page cni')),
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
  return ProviderScope.containerOf(
    tester.element(find.byType(PageKycRecapitulatif)),
  );
}

Finder get _boutonSoumettre =>
    find.widgetWithText(FilledButton, 'Soumettre mon dossier');

Future<void> _cocherConsentement(WidgetTester tester) async {
  final case_ = find.byType(CheckboxListTile);
  await tester.ensureVisible(case_);
  await tester.tap(case_);
  await tester.pump();
}

Future<void> _soumettre(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('le bouton exige le consentement, puis la soumission réussit', (
    tester,
  ) async {
    final kyc = _FauxKyc(_dossierComplet());
    final conteneur = await _afficher(tester, kyc);
    conteneur
        .read(brouillonKycProvider.notifier)
        .choisir(
          TypeDocumentKyc.photoFaciale,
          FichierLocal(
            fichier: XFile.fromData(Uint8List(3)),
            typeMime: 'image/jpeg',
            taille: 3,
          ),
        );
    conteneur
        .read(brouillonKycProvider.notifier)
        .marquerEnvoyee(TypeDocumentKyc.photoFaciale);
    await tester.pump();

    expect(tester.widget<FilledButton>(_boutonSoumettre).onPressed, isNull);

    await _cocherConsentement(tester);
    expect(tester.widget<FilledButton>(_boutonSoumettre).onPressed, isNotNull);

    await _soumettre(tester);

    expect(kyc.cles, hasLength(1));
    expect(find.text('page dossier'), findsOneWidget);
    expect(
      find.text(
        'Ton dossier a bien été transmis. Nous t\'informerons dès que sa vérification sera terminée.',
      ),
      findsOneWidget,
    );
    // Les photos gardées en mémoire sont effacées après la soumission.
    expect(conteneur.read(brouillonKycProvider).photos, isEmpty);
  });

  testWidgets(
    'dossier incomplet : étapes manquantes listées, envoi impossible',
    (tester) async {
      final kyc = _FauxKyc(_dossierComplet(selfie: false));
      await _afficher(tester, kyc);
      await _cocherConsentement(tester);

      expect(find.text('Selfie de vérification'), findsWidgets);
      expect(
        find.text("Complète les étapes suivantes avant d'envoyer ton dossier."),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(_boutonSoumettre).onPressed, isNull);
      expect(kyc.cles, isEmpty);
    },
  );

  testWidgets('le numéro de la carte est masqué, affichable à la demande', (
    tester,
  ) async {
    await _afficher(tester, _FauxKyc(_dossierComplet()));

    expect(find.text('•••••456'), findsOneWidget);
    expect(find.text('AB123456'), findsNothing);

    final afficher = find.text('Afficher');
    await tester.ensureVisible(afficher);
    await tester.tap(afficher);
    await tester.pump();
    expect(find.text('AB123456'), findsOneWidget);
  });

  testWidgets('modifier un élément ouvre son étape', (tester) async {
    await _afficher(tester, _FauxKyc(_dossierComplet()));

    final modifier = find.text('Modifier').at(1);
    await tester.ensureVisible(modifier);
    await tester.tap(modifier);
    await tester.pumpAndSettle();
    expect(find.text('page cni'), findsOneWidget);
  });

  testWidgets('coupure réseau : message, puis nouvel essai avec la même clé', (
    tester,
  ) async {
    final kyc = _FauxKyc(
      _dossierComplet(),
    )..echecs.add(const ApiException(type: TypeErreurApi.reseau, message: 'x'));
    await _afficher(tester, kyc);
    await _cocherConsentement(tester);

    await _soumettre(tester);
    expect(find.text('Pas de connexion internet.'), findsOneWidget);
    expect(find.text('page dossier'), findsNothing);

    await _soumettre(tester);
    expect(kyc.cles, hasLength(2));
    expect(kyc.cles[0], kyc.cles[1]);
    expect(find.text('page dossier'), findsOneWidget);
  });

  testWidgets(
    'réponse perdue mais soumission enregistrée : succès, sans seconde soumission',
    (tester) async {
      final kyc = _FauxKyc(_dossierComplet())
        ..enregistreMalgreEchec = true
        ..echecs.add(
          const ApiException(type: TypeErreurApi.delaiDepasse, message: 'x'),
        );
      await _afficher(tester, kyc);
      await _cocherConsentement(tester);

      await _soumettre(tester);

      expect(kyc.cles, hasLength(1));
      expect(find.text('page dossier'), findsOneWidget);
    },
  );

  testWidgets(
    'refus du serveur : message traduit, nouvelle clé au nouvel essai',
    (tester) async {
      final kyc = _FauxKyc(_dossierComplet())
        ..echecs.add(
          const ApiException(
            type: TypeErreurApi.requeteInvalide,
            message: 'x',
            statusCode: 400,
          ),
        );
      await _afficher(tester, kyc);
      await _cocherConsentement(tester);

      await _soumettre(tester);
      expect(
        find.text(
          "Ton dossier n'a pas pu être envoyé. Vérifie chaque étape, puis réessaie.",
        ),
        findsOneWidget,
      );

      await _soumettre(tester);
      expect(kyc.cles, hasLength(2));
      expect(kyc.cles[0], isNot(kyc.cles[1]));
    },
  );

  testWidgets('double appui : une seule soumission', (tester) async {
    final kyc = _FauxKyc(_dossierComplet())..attente = Completer<void>();
    await _afficher(tester, kyc);
    await _cocherConsentement(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();

    expect(kyc.cles, hasLength(1));

    kyc.attente!.complete();
    await tester.pumpAndSettle();
    expect(kyc.cles, hasLength(1));
    expect(find.text('page dossier'), findsOneWidget);
  });
}
