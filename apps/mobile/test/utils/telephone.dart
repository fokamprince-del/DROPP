import 'package:dropp/utils/telephone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normaliserTelephone', () {
    test('une saisie nationale devient internationale', () {
      expect(normaliserTelephone('670 00 00 01'), '+237670000001');
    });

    test('un numéro déjà international reste identique', () {
      expect(normaliserTelephone('+237 670 00 00 01'), '+237670000001');
    });

    test('le préfixe 00 vaut +', () {
      expect(normaliserTelephone('00237670000001'), '+237670000001');
    });

    test('accepte un numéro étranger', () {
      expect(normaliserTelephone('+33 655 5705 76'), '+33655570576');
    });

    test('refuse le vide et les numéros invalides', () {
      expect(normaliserTelephone(''), isNull);
      expect(normaliserTelephone('12'), isNull);
      expect(normaliserTelephone('abc'), isNull);
    });
  });
}
