import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/router/routes.dart';
import 'package:dropp/core/upload/service_upload.dart';
import 'package:dropp/features/vendeur/data/kyc_repository.dart';
import 'package:dropp/features/vendeur/data/modeles_kyc.dart';
import 'package:dropp/features/vendeur/ui/pages/reprendre_dossier_kyc.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FauxKyc extends KycRepository {
  _FauxKyc(this.dossier) : super(ApiClient(Dio()), ServiceUpload(Dio()));

  final DossierKyc? dossier;

  @override
  Future<DossierKyc?> monDossier() async => dossier;
}

Future<void> _afficher(WidgetTester tester, DossierKyc dossier) async {
  final routeur = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: SingleChildScrollView(child: ReprendreDossierKyc()),
        ),
      ),
      GoRoute(path: Routes.kycCni, builder: (_, _) => const Text('page cni')),
      GoRoute(
        path: Routes.kycSelfie,
        builder: (_, _) => const Text('page selfie'),
      ),
    ],
  );
  addTearDown(routeur.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [kycRepositoryProvider.overrideWithValue(_FauxKyc(dossier))],
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

DossierKyc _dossierSansSelfie() => DossierKyc(
  id: 'd1',
  statut: StatutDossierKyc.enAttente,
  documents: const [
    DocumentKyc(id: 'a', type: TypeDocumentKyc.cniRecto, statut: 'SOUMIS'),
    DocumentKyc(id: 'b', type: TypeDocumentKyc.cniVerso, statut: 'SOUMIS'),
  ],
  donnees: DonneesCni(
    nomLegal: 'NGO',
    prenomLegal: 'Awa',
    numeroCni: 'AB123456',
    dateNaissance: DateTime.utc(1990, 5, 21),
    lieuNaissance: 'Douala',
    dateEtablissement: DateTime.utc(2020, 1, 2),
    dateExpiration: DateTime.utc(2030, 1, 2),
  ),
);

void main() {
  testWidgets('les étapes faites restent accessibles pour être modifiées', (
    tester,
  ) async {
    await _afficher(tester, _dossierSansSelfie());

    expect(find.text('Terminé · toucher pour modifier'), findsNWidgets(2));
    expect(find.text('À faire'), findsOneWidget);
    expect(find.text("Disponible après l'étape précédente"), findsOneWidget);

    await tester.tap(find.text("Carte d'identité"));
    await tester.pumpAndSettle();
    expect(find.text('page cni'), findsOneWidget);
  });

  testWidgets('« Reprendre » mène à la première étape à faire', (tester) async {
    await _afficher(tester, _dossierSansSelfie());

    await tester.tap(find.text('Reprendre ma vérification'));
    await tester.pumpAndSettle();
    expect(find.text('page selfie'), findsOneWidget);
  });
}
