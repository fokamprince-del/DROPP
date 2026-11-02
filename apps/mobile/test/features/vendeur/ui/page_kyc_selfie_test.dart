import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/router/routes.dart';
import 'package:dropp/core/upload/service_upload.dart';
import 'package:dropp/features/vendeur/data/kyc_repository.dart';
import 'package:dropp/features/vendeur/data/modeles_kyc.dart';
import 'package:dropp/features/vendeur/ui/pages/capture_selfie.dart';
import 'package:dropp/features/vendeur/ui/pages/page_kyc_selfie.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FauxKyc extends KycRepository {
  _FauxKyc() : super(ApiClient(Dio()), ServiceUpload(Dio()));

  final documents = <DocumentKyc>[];
  final envoyes = <TypeDocumentKyc>[];

  @override
  Future<DossierKyc?> monDossier() async => DossierKyc(
    id: 'd1',
    statut: StatutDossierKyc.enAttente,
    documents: List.of(documents),
  );

  @override
  Future<DocumentKyc> envoyerDocument({
    required TypeDocumentKyc type,
    required FichierLocal fichier,
    void Function(double)? onProgress,
  }) async {
    envoyes.add(type);
    final document = DocumentKyc(id: type.name, type: type, statut: 'SOUMIS');
    documents.add(document);
    return document;
  }
}

class _FausseCapture implements CaptureSelfie {
  _FausseCapture(this.resultat);

  final FichierLocal? resultat;
  int appels = 0;

  @override
  Future<FichierLocal?> capturer(BuildContext context) async {
    appels++;
    return resultat;
  }
}

Future<void> _afficher(
  WidgetTester tester,
  _FauxKyc kyc,
  _FausseCapture capture,
) async {
  final routeur = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const PageKycSelfie()),
      GoRoute(
        path: Routes.kycRecapitulatif,
        builder: (_, _) => const Text('page récapitulatif'),
      ),
    ],
  );
  addTearDown(routeur.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        kycRepositoryProvider.overrideWithValue(kyc),
        captureSelfieProvider.overrideWithValue(capture),
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

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  final photo = FichierLocal(
    fichier: XFile.fromData(Uint8List(3), name: 'photo.jpeg'),
    typeMime: 'image/jpeg',
    taille: 1,
  );

  testWidgets('consignes visibles, aperçu à valider, envoi, puis continuer', (
    tester,
  ) async {
    final kyc = _FauxKyc();
    final capture = _FausseCapture(photo);
    await _afficher(tester, kyc, capture);

    expect(find.text('Avant de commencer'), findsOneWidget);
    expect(find.text('Regarde l\'objectif.'), findsOneWidget);
    final continuer = find.widgetWithText(FilledButton, 'Continuer');
    expect(tester.widget<FilledButton>(continuer).onPressed, isNull);

    await _toucher(tester, find.text('Prendre mon selfie'));
    expect(capture.appels, 1);
    expect(find.text('À vérifier'), findsOneWidget);
    expect(kyc.envoyes, isEmpty);

    await _toucher(tester, find.text('Utiliser cette photo'));
    expect(kyc.envoyes, [TypeDocumentKyc.photoFaciale]);
    expect(find.text('Envoyé'), findsOneWidget);
    expect(tester.widget<FilledButton>(continuer).onPressed, isNotNull);

    await tester.tap(continuer);
    await tester.pumpAndSettle();
    expect(find.text('page récapitulatif'), findsOneWidget);
  });

  testWidgets('fermer la caméra ne change rien', (tester) async {
    final kyc = _FauxKyc();
    final capture = _FausseCapture(null);
    await _afficher(tester, kyc, capture);

    await _toucher(tester, find.text('Prendre mon selfie'));

    expect(capture.appels, 1);
    expect(find.text('À vérifier'), findsNothing);
    expect(find.text('Prendre mon selfie'), findsOneWidget);
    expect(kyc.envoyes, isEmpty);
  });

  testWidgets('aucune option « galerie » pour le selfie', (tester) async {
    await _afficher(tester, _FauxKyc(), _FausseCapture(photo));
    expect(find.text('Choisir dans la galerie'), findsNothing);
  });
}
