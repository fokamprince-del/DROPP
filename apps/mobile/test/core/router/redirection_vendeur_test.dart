import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/auth/utilisateur.dart';
import 'package:dropp/core/router/redirection.dart';
import 'package:dropp/core/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

SessionConnectee _session({required bool estVendeur, String? statut}) =>
    SessionConnectee(
      Utilisateur(
        id: 'u1',
        prenom: 'Awa',
        nom: 'Ngo Bassa',
        email: null,
        emailVerifie: false,
        telephone: '+237670000001',
        telephoneVerifie: true,
        statutCompte: 'ACTIF',
        estClient: true,
        estVendeur: estVendeur,
        statutVendeur: statut,
      ),
    );

String? _va(EtatSession s, String chemin) => redirection(s, Uri.parse(chemin));

void main() {
  test('un non-vendeur ne voit pas l’espace vendeur', () {
    expect(
      _va(_session(estVendeur: false), Routes.espaceVendeur),
      Routes.devenirVendeur,
    );
  });

  test('un vendeur en attente reste sur le parcours de vérification', () {
    final s = _session(estVendeur: true, statut: 'EN_ATTENTE_VALIDATION');
    expect(_va(s, Routes.devenirVendeur), isNull);
    expect(_va(s, Routes.espaceVendeur), Routes.devenirVendeur);
  });

  test('un vendeur suspendu n’accède pas à l’espace vendeur', () {
    final s = _session(estVendeur: true, statut: 'SUSPENDU');
    expect(_va(s, Routes.espaceVendeur), Routes.devenirVendeur);
  });

  test('un vendeur actif va à l’espace vendeur', () {
    final s = _session(estVendeur: true, statut: 'ACTIF');
    expect(_va(s, Routes.espaceVendeur), isNull);
    expect(_va(s, Routes.devenirVendeur), Routes.espaceVendeur);
  });
}
