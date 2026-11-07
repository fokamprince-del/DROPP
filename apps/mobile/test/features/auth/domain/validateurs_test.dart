import 'package:dropp/features/auth/domain/validateurs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requis', () {
    expect(validerRequis('  '), ErreurChamp.requis);
    expect(validerRequis('Awa'), isNull);
  });

  test('email facultatif', () {
    expect(validerEmailFacultatif(''), isNull);
    expect(validerEmailFacultatif('awa@exemple.cm'), isNull);
    expect(validerEmailFacultatif('awa@exemple'), ErreurChamp.emailInvalide);
  });

  test('mot de passe : 8 caractères, espaces conservés', () {
    expect(
      validerNouveauMotDePasse('1234567'),
      ErreurChamp.motDePasseTropCourt,
    );
    expect(validerNouveauMotDePasse('1234 678'), isNull);
    expect(validerNouveauMotDePasse(''), ErreurChamp.requis);
  });

  test('code à 6 chiffres', () {
    expect(validerCode('12345'), ErreurChamp.codeIncomplet);
    expect(validerCode('12345a'), ErreurChamp.codeIncomplet);
    expect(validerCode('123456'), isNull);
  });

  test('la force croît avec la qualité du mot de passe', () {
    expect(forceMotDePasse(''), 0);
    expect(forceMotDePasse('abc'), 0);
    expect(forceMotDePasse('abcdefgh'), 1);
    expect(forceMotDePasse('abcdefg1'), 2);
    expect(forceMotDePasse('Abcdefg1'), 3);
    expect(forceMotDePasse('Abcdefg1!xyz'), 4);
  });
}
