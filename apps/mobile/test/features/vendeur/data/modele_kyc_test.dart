import 'package:dropp/features/vendeur/data/modeles_kyc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('numéro de CNI : espaces et tirets retirés, majuscules', () {
    expect(normaliserNumeroCni(' ab-123 456 '), 'AB123456');
    expect(numeroCniValide('AB123456'), isTrue);
    expect(numeroCniValide('AB12'), isFalse);
    expect(numeroCniValide('ab123456'), isFalse);
  });

  test('les dates sont lues comme des jours UTC', () {
    expect(lireJour('2026-05-21'), DateTime.utc(2026, 5, 21));
    expect(lireJour('1990-05-21T00:00:00.000Z'), DateTime.utc(1990, 5, 21));
    expect(lireJour(null), isNull);
    expect(jourVersApi(DateTime.utc(1990, 5, 21)), '1990-05-21T00:00:00.000Z');
  });

  test('des données incomplètes ne peuvent pas être confirmées', () {
    const partielles = DonneesCni(nomLegal: 'NGO');
    expect(partielles.complet, isFalse);
    expect(partielles.versJsonConfirmation, throwsStateError);
  });

  test('la confirmation envoie tous les champs au bon format', () {
    final json = DonneesCni(
      nomLegal: ' NGO BASSA ',
      prenomLegal: 'Awa',
      numeroCni: 'ab-123456',
      dateNaissance: DateTime.utc(1990, 5, 21),
      lieuNaissance: 'Douala',
      dateEtablissement: DateTime.utc(2020, 1, 2),
      dateExpiration: DateTime.utc(2030, 1, 2),
    ).versJsonConfirmation();

    expect(json['nomLegal'], 'NGO BASSA');
    expect(json['numeroCni'], 'AB123456');
    expect(json['dateNaissance'], '1990-05-21T00:00:00.000Z');
  });

  test('dossier rejeté : statut, motif, documents inconnus ignorés', () {
    final dossier = DossierKyc.depuisJson(<String, dynamic>{
      'statut': 'REJETE',
      'id': 'd1',
      'motifRejet': 'Photo floue',
      'consentementLe': null,
      'documents': <dynamic>[
        <String, dynamic>{
          'statut': 'REJETE',
          'id': 'a',
          'typeDocument': 'CNI_RECTO',
        },
        <String, dynamic>{
          'statut': 'SOUMIS',
          'id': 'b',
          'typeDocument': 'AUTRE_TYPE',
        },
      ],
    });

    expect(dossier.statut, StatutDossierKyc.rejete);
    expect(dossier.motifRejet, 'Photo floue');
    expect(dossier.documents, hasLength(1));
    expect(dossier.document(TypeDocumentKyc.cniRecto)?.refuse, isTrue);
    expect(dossier.documentsComplets, isFalse);
  });

  test('un statut inconnu ne fait pas planter', () {
    expect(StatutDossierKyc.depuisApi('NOUVEAU'), StatutDossierKyc.inconnu);
    expect(StatutDossierKyc.enCoursVerification.enVerification, isTrue);
    expect(StatutDossierKyc.enAttente.enVerification, isFalse);
  });
}
