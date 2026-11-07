import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/features/auth/data/auth_repository.dart';
import 'package:dropp/features/auth/data/modeles_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class _FauxApi extends ApiClient {
  _FauxApi(this.reponse) : super(Dio());

  final Map<String, dynamic> reponse;
  String? dernierChemin;
  Object? dernierCorps;
  Options? dernieresOptions;

  @override
  Future<T> post<T>(String chemin, {Object? data, Options? options}) async {
    dernierChemin = chemin;
    dernierCorps = data;
    dernieresOptions = options;
    return reponse as T;
  }
}

void main() {
  test("l'inscription n'envoie pas d'email vide et renvoie le jeton", () async {
    final api = _FauxApi({'verificationToken': 'vt1'});
    final jeton = await AuthRepository(api).inscrire(
      const DonneesInscription(
        prenom: ' Awa ',
        nom: 'Ngo Bassa',
        sexe: Sexe.feminin,
        telephone: '+237670000001',
        motDePasse: ' secret123 ',
        email: '  ',
      ),
    );

    expect(jeton, 'vt1');
    expect(api.dernierChemin, '/auth/inscription');
    final corps = api.dernierCorps! as Map<String, dynamic>;
    expect(corps.containsKey('email'), isFalse);
    expect(corps['prenom'], 'Awa');
    expect(corps['motDePasse'], ' secret123 ');
    expect(corps['sexe'], 'FEMININ');
  });

  test('la connexion d\'un compte non vérifié demande le code', () async {
    final api = _FauxApi({
      'verificationRequise': true,
      'verificationToken': 'vt2',
    });
    final resultat = await AuthRepository(api)
        .connecter(identifiant: '670000001', motDePasse: 'secret123');

    expect(resultat, isA<VerificationRequise>());
    expect((resultat as VerificationRequise).verificationToken, 'vt2');
  });

  test('la connexion réussie renvoie les jetons', () async {
    final api = _FauxApi({
      'verificationRequise': false,
      'accessToken': 'a',
      'refreshToken': 'r',
      'expiresIn': 900,
    });
    final resultat = await AuthRepository(api)
        .connecter(identifiant: '670000001', motDePasse: 'secret123');

    expect(resultat, isA<ConnexionReussie>());
    expect((resultat as ConnexionReussie).jetons.accessToken, 'a');
  });

  test("la réinitialisation joint la clé d'idempotence", () async {
    final api = _FauxApi({
      'accessToken': 'a',
      'refreshToken': 'r',
      'expiresIn': 900,
    });
    await AuthRepository(api).reinitialiserMotDePasse(
      verificationToken: 'vt3',
      code: '123456',
      nouveauMotDePasse: 'nouveau123',
      cleIdempotence: 'cle-unique-1',
    );

    expect(api.dernierChemin, '/auth/reinitialiser-mot-de-passe');
    expect(api.dernieresOptions?.headers?['Idempotency-Key'], 'cle-unique-1');
  });

  group('email', () {
    test('le renvoi du code renvoie l’adresse ciblée', () async {
      final api = _FauxApi({
        'email': 'awa@exemple.cm',
        'expireA': '2026-10-26T10:05:00.000Z',
      });
      final email = await AuthRepository(api).envoyerCodeEmail();

      expect(api.dernierChemin, '/auth/email/envoyer-code');
      expect(email, 'awa@exemple.cm');
    });

    test(
      'le changement normalise l’adresse et envoie le mot de passe',
      () async {
        final api = _FauxApi({
          'email': 'awa@exemple.cm',
          'expireA': '2026-10-26T10:05:00.000Z',
        });
        await AuthRepository(api)
            .changerEmail(email: ' Awa@Exemple.CM ', motDePasse: 'secret123');

        expect(api.dernierChemin, '/auth/email/changer');
        expect(api.dernierCorps, {
          'email': 'awa@exemple.cm',
          'motDePasse': 'secret123',
        });
      },
    );

    test('la vérification n’envoie l’adresse que pour un changement', () async {
      final api = _FauxApi({'email': 'awa@exemple.cm', 'emailVerifie': true});
      await AuthRepository(api).verifierEmail('123456');
      expect(api.dernierChemin, '/auth/email/verifier');
      expect(api.dernierCorps, {'code': '123456'});

      await AuthRepository(api).verifierEmail('123456', email: 'b@ex.cm');
      expect(api.dernierCorps, {'code': '123456', 'email': 'b@ex.cm'});
    });
  });
}
