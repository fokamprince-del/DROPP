import 'package:dropp/core/api/api_exception.dart';
import 'package:dropp/features/fil/application/vues_publications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('une publication n’est signalée qu’une fois', () async {
    final envoyees = <String>[];
    final vues = VuesPublications((id) async => envoyees.add(id));

    await vues.signaler('a');
    await vues.signaler('a');
    await vues.signaler('b');

    expect(envoyees, ['a', 'b']);
  });

  test('après un échec, le prochain affichage réessaie', () async {
    var tentatives = 0;
    final vues = VuesPublications((id) async {
      tentatives++;
      if (tentatives == 1) {
        throw const ApiException(
          type: TypeErreurApi.reseau,
          message: 'Pas de connexion internet.',
        );
      }
    });

    await vues.signaler('a');
    await vues.signaler('a');
    await vues.signaler('a');

    expect(tentatives, 2);
  });
}
