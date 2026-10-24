import 'package:dropp/features/auth/domain/identifiant.dart';
import 'package:dropp/features/auth/domain/validateurs.dart';
import 'package:dropp/utils/telephone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normaliserIdentifiant', () {
    test('un email reste un email', () {
      expect(normaliserIdentifiant(' awa@exemple.cm '), 'awa@exemple.cm');
    });

    test('un téléphone devient international', () {
      expect(normaliserIdentifiant('670 00 00 01'), '+237670000001');
    });

    test('un email invalide est refusé', () {
      expect(normaliserIdentifiant('awa@exemple'), isNull);
    });

    test('du texte quelconque est refusé', () {
      expect(normaliserIdentifiant('bonjour'), isNull);
    });
  });

  group('validerIdentifiant', () {
    test('vide : requis', () {
      expect(validerIdentifiant(' '), ErreurChamp.requis);
    });

    test('invalide', () {
      expect(validerIdentifiant('12'), ErreurChamp.identifiantInvalide);
    });

    test('valide', () {
      expect(validerIdentifiant('awa@exemple.cm'), isNull);
    });
  });

  test('masquerTelephone', () {
    expect(masquerTelephone('+237670000001'), '+237670 •• •• 01');
    expect(masquerTelephone('1234'), '1234');
  });
}
