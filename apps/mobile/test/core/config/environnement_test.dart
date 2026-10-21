import 'package:dropp/core/config/environnement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Environnement.valider', () {
    test('accepte http en debug', () {
      expect(
        () => Environnement.valider('http://10.0.2.2:3000/v1', release: false),
        returnsNormally,
      );
    });

    test('accepte https en release', () {
      expect(
        () => Environnement.valider('https://api.dropp.cm/v1', release: true),
        returnsNormally,
      );
    });

    test('refuse http en release', () {
      expect(
        () => Environnement.valider('http://10.0.2.2:3000/v1', release: true),
        throwsStateError,
      );
    });

    test('refuse une URL invalide', () {
      expect(
        () => Environnement.valider('pas une url', release: false),
        throwsStateError,
      );
    });
  });

  test('origineServeur retire le chemin et garde le port', () {
    expect(Environnement.origineServeur, 'http://10.0.2.2:3000');
  });
}