import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/upload/service_upload.dart';
import 'package:dropp/features/vendeur/data/kyc_repository.dart';
import 'package:dropp/features/vendeur/data/modeles_kyc.dart';
import 'package:dropp/features/vendeur/data/selecteur_photo.dart';
import 'package:dropp/features/vendeur/ui/widgets/verification_vendeur.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    final document = DocumentKyc(id: 'x', type: type, statut: 'SOUMIS');
    documents.add(document);
    return document;
  }
}

class _FauxSelecteur implements SelecteurPhoto {
  _FauxSelecteur({this.taille = 1000});

  final int taille;
  bool? dernierSelfie;
  final supprimes = <String>[];

  @override
  Future<FichierLocal?> prendre({
    required bool selfie,
    bool galerie = false,
    int tailleMaxMo = tailleMaxDocumentKyc,
  }) async {
    dernierSelfie = selfie;
    return FichierLocal(
      fichier: XFile.fromData(
        Uint8List.fromList([1, 2, 3, 4, 5]),
        path: '/tmp/p.jpg',
        mimeType: 'image/jpeg',
      ),
      typeMime: '/tmp/p.jpg',
      taille: taille,
    );
  }

  @override
  Future<void> supprimer(String chemin) async => supprimes.add(chemin);
}

Future<void> _afficher(
  WidgetTester tester,
  _FauxKyc kyc,
  _FauxSelecteur selecteur,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        kycRepositoryProvider.overrideWithValue(kyc),
        selecteurPhotoProvider.overrideWithValue(selecteur),
      ],
      child: MaterialApp(
        theme: ThemeDropp.clair,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: VerificationVendeur()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('trois documents à fournir, galerie seulement pour la CNI', (
    tester,
  ) async {
    await _afficher(tester, _FauxKyc(), _FauxSelecteur());

    expect(find.text('Prendre la photo'), findsNWidgets(3));
    expect(find.text('Choisir dans la galerie'), findsNWidgets(2));
  });

  testWidgets(
    'le selfie est envoyé, la photo supprimée, le statut mis à jour',
    (tester) async {
      final kyc = _FauxKyc();
      final selecteur = _FauxSelecteur();
      await _afficher(tester, kyc, selecteur);

      final bouton = find.text('Prendre la photo').last;
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.pumpAndSettle();

      expect(kyc.envoyes, [TypeDocumentKyc.photoFaciale]);
      expect(selecteur.dernierSelfie, isTrue);
      expect(selecteur.supprimes, ['/tmp/p.jpg']);
      expect(find.text('Envoyé'), findsOneWidget);
      expect(find.text('Reprendre'), findsOneWidget);
    },
  );

}
