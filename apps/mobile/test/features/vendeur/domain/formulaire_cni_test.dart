import 'package:dropp/features/vendeur/data/modeles_kyc.dart';
import 'package:dropp/features/vendeur/domain/formulaire_cni.dart';
import 'package:dropp/shared/forms/erreur_champ.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final aujourdhui = DateTime.utc(2026, 10, 30);

  test('analyse et formatage des dates', () {
    expect(analyserDateSaisie('21/05/1990'), DateTime.utc(1990, 5, 21));
    expect(analyserDateSaisie('31/02/2020'), isNull);
    expect(analyserDateSaisie('1/5/1990'), isNull);
    expect(analyserDateSaisie(''), isNull);
    expect(formaterJour(DateTime.utc(1990, 5, 1)), '01/05/1990');
  });

  test('date de naissance', () {
    ErreurChamp? v(String s) => validerDateNaissance(s, aujourdhui: aujourdhui);
    expect(v(''), ErreurChamp.requis);
    expect(v('31/02/1990'), ErreurChamp.dateInvalide);
    expect(v('01/01/1899'), ErreurChamp.dateNaissanceImpossible);
    expect(v('31/12/2026'), ErreurChamp.dateNaissanceImpossible);
    expect(v('21/05/1990'), isNull);
  });

  test('date de délivrance', () {
    ErreurChamp? v(String s) =>
        validerDateDelivrance(s, aujourdhui: aujourdhui);
    expect(v('31/12/2026'), ErreurChamp.dateFuture);
    expect(v('02/01/2020'), isNull);
  });

  test("l'expiration doit suivre la délivrance", () {
    expect(
      validerDateExpiration('01/01/2020', '02/01/2020'),
      ErreurChamp.expirationAvantDelivrance,
    );
    expect(validerDateExpiration('02/01/2030', '02/01/2020'), isNull);
    expect(validerDateExpiration('02/01/2030', ''), isNull);
  });

  test('numéro de carte : espaces et tirets acceptés', () {
    expect(validerNumeroCni('ab-123 456'), isNull);
    expect(validerNumeroCni('AB12'), ErreurChamp.numeroCniInvalide);
    expect(validerNumeroCni(' '), ErreurChamp.requis);
  });

  test("l'expiration : refusée si dépassée, et doit suivre la délivrance", () {
    final ref = DateTime.utc(2026, 10, 30);
    expect(
      validerDateExpiration('01/01/2020', '02/01/2019', aujourdhui: ref),
      ErreurChamp.carteExpiree,
    );
    expect(
      validerDateExpiration('30/10/2026', '02/01/2019', aujourdhui: ref),
      ErreurChamp.carteExpiree,
    );
    expect(
      validerDateExpiration(
        '01/01/2020',
        '02/01/2020',
        aujourdhui: DateTime.utc(2019),
      ),
      ErreurChamp.expirationAvantDelivrance,
    );
    expect(
      validerDateExpiration('02/01/2030', '02/01/2020', aujourdhui: ref),
      isNull,
    );
    expect(validerDateExpiration('02/01/2030', '', aujourdhui: ref), isNull);
  });

  test('la naissance doit précéder la délivrance', () {
    final ref = DateTime.utc(2026, 10, 30);
    expect(
      validerDateNaissance(
        '02/01/2020',
        delivrance: '02/01/2020',
        aujourdhui: ref,
      ),
      ErreurChamp.naissanceIncoherente,
    );
    expect(
      validerDateNaissance(
        '21/05/1990',
        delivrance: '02/01/2020',
        aujourdhui: ref,
      ),
      isNull,
    );
  });

  group('FormulaireCni', () {
    final lues = DonneesCni(
      nomLegal: ' NGO BASSA ',
      prenomLegal: '',
      numeroCni: 'ab 123456',
      dateNaissance: DateTime.utc(1990, 5, 21),
    );

    test("n'extrait que les champs reconnus, normalisés", () {
      final valeurs = FormulaireCni.valeursLues(lues);
      expect(valeurs.keys, [ChampCni.nom, ChampCni.numero, ChampCni.naissance]);
      expect(valeurs[ChampCni.nom], 'NGO BASSA');
      expect(valeurs[ChampCni.numero], 'AB123456');
      expect(valeurs[ChampCni.naissance], '21/05/1990');
    });

    test('la lecture ne supprime pas ce que l\'utilisateur a tapé', () {
      const saisi = FormulaireCni(
        valeurs: {ChampCni.lieu: 'Douala', ChampCni.nom: 'ancien'},
      );
      final apres = saisi.avecExtraction(lues);
      expect(apres.valeur(ChampCni.lieu), 'Douala');
      expect(apres.valeur(ChampCni.nom), 'NGO BASSA');
    });

    test('incomplet : pas de données', () {
      expect(FormulaireCni.depuisDonnees(lues).versDonnees(), isNull);
    });

    test('complet : données prêtes à confirmer', () {
      final donnees = FormulaireCni(
        valeurs: {
          ChampCni.nom: 'NGO BASSA',
          ChampCni.prenom: 'Awa',
          ChampCni.numero: 'ab-123456',
          ChampCni.naissance: '21/05/1990',
          ChampCni.lieu: 'Douala',
          ChampCni.delivrance: '02/01/2020',
          ChampCni.expiration: '02/01/2030',
        },
      ).versDonnees();

      expect(donnees, isNotNull);
      expect(donnees!.numeroCni, 'AB123456');
      expect(donnees.dateNaissance, DateTime.utc(1990, 5, 21));
      expect(donnees.complet, isTrue);
    });
  });
}
