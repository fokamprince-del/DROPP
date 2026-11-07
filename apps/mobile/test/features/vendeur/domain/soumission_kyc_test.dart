import 'package:dropp/core/api/api_exception.dart';
import 'package:dropp/features/vendeur/data/modeles_kyc.dart';
import 'package:dropp/features/vendeur/domain/etape_kyc.dart';
import 'package:dropp/features/vendeur/domain/soumission_kyc.dart';
import 'package:flutter_test/flutter_test.dart';

DocumentKyc _doc(
  TypeDocumentKyc type, {
  String id = 'x',
  String statut = 'SOUMIS',
}) => DocumentKyc(id: '$id-${type.name}', type: type, statut: statut);

final _donnees = DonneesCni(
  nomLegal: 'NGO',
  prenomLegal: 'Awa',
  numeroCni: 'AB123456',
  dateNaissance: DateTime.utc(1990, 5, 21),
  lieuNaissance: 'Douala',
  dateEtablissement: DateTime.utc(2020, 1, 2),
  dateExpiration: DateTime.utc(2030, 1, 2),
);

DossierKyc _dossier({
  StatutDossierKyc statut = StatutDossierKyc.enAttente,
  List<DocumentKyc>? documents,
  DonneesCni? donnees,
  String id = 'x',
}) => DossierKyc(
  id: 'd',
  statut: statut,
  documents:
      documents ?? [for (final t in TypeDocumentKyc.values) _doc(t, id: id)],
  donnees: donnees ?? _donnees,
);

void main() {
  test('étapes incomplètes', () {
    expect(etapesIncompletes(_dossier()), isEmpty);
    expect(
      etapesIncompletes(_dossier(documents: [_doc(TypeDocumentKyc.cniRecto)])),
      [EtapeKyc.cni, EtapeKyc.informations, EtapeKyc.selfie],
    );
    expect(etapesIncompletes(_dossier(donnees: const DonneesCni())), [
      EtapeKyc.informations,
      EtapeKyc.selfie,
    ]);
  });

  test('prêt à soumettre : complet et pas déjà soumis', () {
    expect(pretASoumettre(_dossier()), isTrue);
    expect(pretASoumettre(null), isFalse);
    expect(
      pretASoumettre(_dossier(statut: StatutDossierKyc.enCoursVerification)),
      isFalse,
    );
    expect(pretASoumettre(_dossier(statut: StatutDossierKyc.valide)), isFalse);
    expect(pretASoumettre(_dossier(donnees: const DonneesCni())), isFalse);
  });

  test('un document refusé empêche la soumission', () {
    final d = _dossier(
      documents: [
        _doc(TypeDocumentKyc.cniRecto, statut: 'REJETE'),
        _doc(TypeDocumentKyc.cniVerso),
        _doc(TypeDocumentKyc.photoFaciale),
      ],
    );
    expect(pretASoumettre(d), isFalse);
  });

  test('la signature change quand le contenu change, pas sinon', () {
    expect(signatureDossier(_dossier()), signatureDossier(_dossier()));
    expect(
      signatureDossier(_dossier()),
      isNot(signatureDossier(_dossier(id: 'y'))),
    );
    final autreNom = DonneesCni(
      nomLegal: 'AUTRE',
      prenomLegal: _donnees.prenomLegal,
      numeroCni: _donnees.numeroCni,
      dateNaissance: _donnees.dateNaissance,
      lieuNaissance: _donnees.lieuNaissance,
      dateEtablissement: _donnees.dateEtablissement,
      dateExpiration: _donnees.dateExpiration,
    );
    expect(
      signatureDossier(_dossier()),
      isNot(signatureDossier(_dossier(donnees: autreNom))),
    );
  });

  test('le numéro est masqué sauf les trois derniers caractères', () {
    expect(masquerNumeroCni('AB123456'), '•••••456');
    expect(masquerNumeroCni('123'), '123');
  });

  test('issue incertaine : réseau, délai, serveur, conflit', () {
    for (final type in [
      TypeErreurApi.reseau,
      TypeErreurApi.delaiDepasse,
      TypeErreurApi.serveur,
      TypeErreurApi.inconnu,
      TypeErreurApi.conflit,
    ]) {
      expect(issueIncertaine(type), isTrue, reason: '$type');
    }
    for (final type in [
      TypeErreurApi.requeteInvalide,
      TypeErreurApi.interdit,
      TypeErreurApi.introuvable,
      TypeErreurApi.nonAuthentifie,
    ]) {
      expect(issueIncertaine(type), isFalse, reason: '$type');
    }
  });

  test('chemin ouvert depuis le récapitulatif', () {
    expect(
      cheminDepuisRecapitulatif('/devenir-vendeur/cni'),
      '/devenir-vendeur/cni?depuis=recap',
    );
  });
}
