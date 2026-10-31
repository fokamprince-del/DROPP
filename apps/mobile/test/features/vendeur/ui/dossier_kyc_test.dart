import 'package:dropp/core/router/routes.dart';
import 'package:dropp/features/vendeur/data/modeles_kyc.dart';
import 'package:dropp/features/vendeur/domain/etape_kyc.dart';
import 'package:flutter_test/flutter_test.dart';

DocumentKyc _doc(TypeDocumentKyc type, {String statut = 'SOUMIS'}) =>
    DocumentKyc(id: type.name, type: type, statut: statut);

DossierKyc _dossier({
  StatutDossierKyc statut = StatutDossierKyc.enAttente,
  List<DocumentKyc> documents = const [],
  DonneesCni donnees = const DonneesCni(),
}) =>
    DossierKyc(id: 'd', statut: statut, documents: documents, donnees: donnees);

final _cni = [_doc(TypeDocumentKyc.cniRecto), _doc(TypeDocumentKyc.cniVerso)];
final _donnees = DonneesCni(
  nomLegal: 'NGO',
  prenomLegal: 'Awa',
  numeroCni: 'AB123456',
  dateNaissance: DateTime.utc(1990, 5, 21),
  lieuNaissance: 'Douala',
  dateEtablissement: DateTime.utc(2020, 1, 2),
  dateExpiration: DateTime.utc(2030, 1, 2),
);

void main() {
  test('sans dossier : on commence par la CNI', () {
    expect(etapeSuivante(null), EtapeKyc.cni);
  });

  test('recto seul : toujours la CNI', () {
    final d = _dossier(documents: [_doc(TypeDocumentKyc.cniRecto)]);
    expect(etapeSuivante(d), EtapeKyc.cni);
  });

  test('un document refusé est à refaire', () {
    final d = _dossier(
      documents: [
        _doc(TypeDocumentKyc.cniRecto, statut: 'REJETE'),
        _doc(TypeDocumentKyc.cniVerso),
      ],
      donnees: _donnees,
    );
    expect(etapeSuivante(d), EtapeKyc.cni);
  });

  test('CNI envoyée, informations manquantes', () {
    expect(etapeSuivante(_dossier(documents: _cni)), EtapeKyc.informations);
  });

  test('informations saisies, selfie manquant', () {
    final d = _dossier(documents: _cni, donnees: _donnees);
    expect(etapeSuivante(d), EtapeKyc.selfie);
  });

  test('tout est prêt : récapitulatif', () {
    final d = _dossier(
      documents: [..._cni, _doc(TypeDocumentKyc.photoFaciale)],
      donnees: _donnees,
    );
    expect(etapeSuivante(d), EtapeKyc.recapitulatif);
  });

  test('dossier soumis ou validé : page du dossier', () {
    expect(
      etapeSuivante(_dossier(statut: StatutDossierKyc.enCoursVerification)),
      EtapeKyc.dossier,
    );
    expect(
      etapeSuivante(_dossier(statut: StatutDossierKyc.valide)),
      EtapeKyc.dossier,
    );
  });

  test('chaque étape a une route', () {
    expect(routePourEtape(EtapeKyc.cni), Routes.kycCni);
    expect(routePourEtape(EtapeKyc.recapitulatif), Routes.kycRecapitulatif);
  });

}