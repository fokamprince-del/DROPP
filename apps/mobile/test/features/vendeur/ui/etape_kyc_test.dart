import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/router/routes.dart';
import 'package:dropp/core/upload/service_upload.dart';
import 'package:dropp/features/vendeur/data/kyc_repository.dart';
import 'package:dropp/features/vendeur/data/modeles_kyc.dart';
import 'package:dropp/features/vendeur/data/selecteur_photo.dart';
import 'package:dropp/features/vendeur/ui/pages/page_kyc_cni.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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

class _FauxSelecteur implements SelecteurPhoto {
  _FauxSelecteur({this.taille = 3});

  final int taille;

  @override
  Future<FichierLocal?> prendre({
    required bool selfie,
    bool galerie = false,
    int tailleMaxMo = 10
  }) async =>
      FichierLocal(fichier: XFile.fromData(
          utf8.encode('Contenu du premier fichier de test'),
          name: 'document1.jpeg',
          mimeType: 'image/jpeg',
        ), 
        typeMime: 'image/jpeg', 
        taille: taille
      );

  @override
  Future<void> supprimer(String chemin) {
    // TODO: implement supprimer
    throw UnimplementedError();
  }

  
}

Future<void> _afficher(
  WidgetTester tester,
  _FauxKyc kyc,
  _FauxSelecteur selecteur,
) async {
  final routeur = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const PageKycCni()),
      GoRoute(
        path: Routes.kycInformations,
        builder: (_, _) => const Text('page informations'),
      ),
    ],
  );
  addTearDown(routeur.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        kycRepositoryProvider.overrideWithValue(kyc),
        selecteurPhotoProvider.overrideWithValue(selecteur),
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
  testWidgets('recto puis verso : aperçu à valider, envoi, puis continuer',
      (tester) async {
    final kyc = _FauxKyc();
    await _afficher(tester, kyc, _FauxSelecteur());

    final continuer = find.widgetWithText(FilledButton, 'Continuer');
    expect(find.text('Prendre la photo'), findsNWidgets(2));
    expect(find.text("Importe d'abord le recto."), findsOneWidget);
    expect(tester.widget<FilledButton>(continuer).onPressed, isNull);

    // Recto : choisi mais pas encore envoyé.
    await _toucher(tester, find.text('Prendre la photo').first);
    expect(find.text('À vérifier'), findsOneWidget);
    expect(kyc.envoyes, isEmpty);

    await _toucher(tester, find.text('Utiliser cette photo'));
    expect(kyc.envoyes, [TypeDocumentKyc.cniRecto]);
    expect(find.text('Envoyé'), findsOneWidget);
    expect(tester.widget<FilledButton>(continuer).onPressed, isNull);

    // Verso, maintenant accessible.
    await _toucher(tester, find.text('Prendre la photo'));
    await _toucher(tester, find.text('Utiliser cette photo'));
    expect(kyc.envoyes, [TypeDocumentKyc.cniRecto, TypeDocumentKyc.cniVerso]);
    expect(tester.widget<FilledButton>(continuer).onPressed, isNotNull);

    await tester.tap(continuer);
    await tester.pumpAndSettle();
    expect(find.text('page informations'), findsOneWidget);
  });

  testWidgets('une photo trop lourde est refusée avant tout envoi',
      (tester) async {
    final kyc = _FauxKyc();
    await _afficher(
      tester,
      kyc,
      _FauxSelecteur(taille: tailleMaxDocumentKyc + 1),
    );

    await _toucher(tester, find.text('Prendre la photo').first);

    expect(
      find.text('Photo trop lourde (10 Mo maximum). Reprends-la.'),
      findsOneWidget,
    );
    expect(find.text('À vérifier'), findsNothing);
    expect(kyc.envoyes, isEmpty);
  });
}